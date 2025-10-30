package app

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"strings"

	"github.com/shikanime/manifests/internal/config"
	"github.com/shikanime/manifests/internal/utils"
	"github.com/shikanime/manifests/internal/vsc"
	"github.com/spf13/cobra"
	"golang.org/x/sync/errgroup"
	"sigs.k8s.io/kustomize/kyaml/kio"
	"sigs.k8s.io/kustomize/kyaml/yaml"
)

var UpdateGitHubWorkflowCmd = &cobra.Command{
	Use:   "githubworkflow [DIR]",
	Short: "Update GitHub Actions in workflows to latest major versions",
	RunE: func(cmd *cobra.Command, args []string) error {
		root := "."
		if len(args) > 0 && strings.TrimSpace(args[0]) != "" {
			root = args[0]
		}
		options := []vsc.GitHubClientOption{
			vsc.WithAuthToken(config.GetGithubToken()),
		}
		token := config.GetGithubToken()
		if token != "" {
			options = append(options, vsc.WithAuthToken(token))
		}
		return runGitHubUpdateWorkflow(cmd.Context(), vsc.NewGitHubClient(options...), root)
	},
}

func runGitHubUpdateWorkflow(ctx context.Context, client *vsc.GitHubClient, root string) error {
	workflowsDir := filepath.Join(root, ".github", "workflows")
	entries, err := os.ReadDir(workflowsDir)
	if err != nil {
		if os.IsNotExist(err) {
			slog.Warn("workflows directory not found", "dir", workflowsDir)
			return nil
		}
		return fmt.Errorf("read workflows dir: %w", err)
	}

	g := new(errgroup.Group)
	for _, e := range entries {
		if e.IsDir() {
			continue
		}
		g.Go(createUpdateGitHubWorkflowJob(ctx, client, filepath.Join(workflowsDir, e.Name())))
	}
	return g.Wait()
}

func createUpdateGitHubWorkflowJob(ctx context.Context, client *vsc.GitHubClient, path string) func() error {
	return func() error {
		if err := createUpdateGitHubWorkflowPipeline(ctx, client, path).Execute(); err != nil {
			slog.Warn("skip github workflow update", "dir", path, "err", err)
			return err
		}
		return nil
	}
}

func createUpdateGitHubWorkflowPipeline(ctx context.Context, client *vsc.GitHubClient, path string) kio.Pipeline {
	return kio.Pipeline{
		Inputs: []kio.Reader{
			kio.LocalPackageReader{
				PackagePath: path,
				FileSkipFunc: func(relPath string) bool {
					return utils.IsGitIgnored(path, relPath)
				},
			},
		},
		Filters: []kio.Filter{
			createUpdateGitHubActionsFilter(ctx, client),
		},
		Outputs: []kio.Writer{
			kio.LocalPackageWriter{
				PackagePath: path,
			},
		},
	}
}

func createUpdateGitHubActionsFilter(ctx context.Context, client *vsc.GitHubClient) kio.Filter {
	return kio.FilterFunc(func(nodes []*yaml.RNode) ([]*yaml.RNode, error) {
		for _, root := range nodes {
			processWorkflowNode(ctx, client, root)
		}
		return nodes, nil
	})
}

func processWorkflowNode(ctx context.Context, client *vsc.GitHubClient, root *yaml.RNode) error {
	jobsNode, err := root.Pipe(yaml.Lookup("jobs"))
	if err != nil {
		slog.Warn("failed to lookup jobs", "error", err)
		return fmt.Errorf("lookup jobs: %w", err)
	}
	if jobsNode == nil {
		slog.Info("no jobs found")
		return nil
	}

	jobNames, err := jobsNode.Fields()
	if err != nil {
		slog.Warn("failed to list jobs", "error", err)
		return fmt.Errorf("get job fields: %w", err)
	}

	for _, j := range jobNames {
		if err := processJob(ctx, client, jobsNode, j); err != nil {
			slog.Warn("job processing error", "job", j, "error", err)
		}
	}
	return nil
}

func processJob(ctx context.Context, client *vsc.GitHubClient, jobsNode *yaml.RNode, jobName string) error {
	jobNode, err := jobsNode.Pipe(yaml.Lookup(jobName))
	if err != nil || jobNode == nil {
		slog.Info("skip job without steps", "job", jobName)
		return nil
	}
	stepsNode, err := jobNode.Pipe(yaml.Lookup("steps"))
	if err != nil || stepsNode == nil {
		slog.Info("job has no steps", "job", jobName)
		return nil
	}
	stepElems, err := stepsNode.Elements()
	if err != nil {
		slog.Warn("failed to get steps", "job", jobName, "error", err)
		return fmt.Errorf("get steps: %w", err)
	}
	wg := new(errgroup.Group)
	for idx, step := range stepElems {
		wg.Go(func() error {
			return processStep(ctx, client, step, jobName, idx)
		})
	}
	return wg.Wait()
}

func processStep(ctx context.Context, client *vsc.GitHubClient, step *yaml.RNode, jobName string, idx int) error {
	usesNode, err := step.Pipe(yaml.Get("uses"))
	if err != nil {
		return fmt.Errorf("get uses: %w", err)
	}
	if usesNode == nil {
		return nil
	}
	curr := strings.TrimSpace(yaml.GetValue(usesNode))
	if curr == "" {
		slog.Info("empty uses value", "job", jobName, "step_index", idx)
		return nil
	}

	actionRef, err := vsc.ParseGitHubActionRef(curr)
	if err != nil {
		slog.Info("non-versioned uses entry; skipping", "job", jobName, "step_index", idx, "uses", curr, "error", err)
		return nil
	}

	// Maintain original behavior: skip versions containing '/'
	if strings.Contains(actionRef.Version, "/") {
		slog.Info("skip uses with slash in version", "job", jobName, "action", fmt.Sprintf("%s/%s", actionRef.Owner, actionRef.Repo), "version", actionRef.Version)
		return nil
	}

	latest, err := client.FindLatestActionTag(ctx, actionRef)
	if err != nil {
		slog.Warn("failed to fetch latest tag with strategy", "action", actionRef.String(), "error", err)
		return nil
	}
	if latest == "" {
		slog.Info("no suitable tag found", "action", actionRef.String())
		return nil
	}

	// Replace inline fmt.Sprintf with GitHubActionRef.String()
	newActionRef := vsc.GitHubActionRef{
		Owner:   actionRef.Owner,
		Repo:    actionRef.Repo,
		Version: latest,
	}
	if err := step.PipeE(yaml.SetField("uses", yaml.NewStringRNode(newActionRef.String()))); err != nil {
		slog.Warn("failed to update uses", "job", jobName, "action", fmt.Sprintf("%s/%s", actionRef.Owner, actionRef.Repo), "error", err)
		return fmt.Errorf("set uses for %s/%s: %w", actionRef.Owner, actionRef.Repo, err)
	}
	slog.Info("updated action", "job", jobName, "action", fmt.Sprintf("%s/%s", actionRef.Owner, actionRef.Repo), "from", actionRef.Version, "to", latest)
	return nil
}
