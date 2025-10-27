package app

import (
	"fmt"
	"io/fs"
	"log/slog"
	"path/filepath"
	"strings"

	"github.com/shikanime/manifests/internal/registry"
	"github.com/shikanime/manifests/internal/utils"
	"github.com/spf13/cobra"
	"golang.org/x/sync/errgroup"
	"sigs.k8s.io/kustomize/kyaml/yaml"
)

var UpdateKustomizationCmd = &cobra.Command{
	Use:   "kustomization [DIR]",
	Short: "Update kustomize image tags",
	RunE: func(cmd *cobra.Command, args []string) error {
		root := "."
		if len(args) > 0 && strings.TrimSpace(args[0]) != "" {
			root = args[0]
		}

		g := new(errgroup.Group)
		if err := utils.WalkDirWithGitignore(root, func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if d.IsDir() {
				return nil
			}
			if !isKustomizationFile(path) {
				return nil
			}
			g.Go(runUpdateKustomization(filepath.Dir(path)))
			return nil
		}); err != nil {
			return err
		}
		return g.Wait()
	},
}

func runUpdateKustomization(path string) func() error {
	return func() error {
		if err := updateKustomizationForDir(path); err != nil {
			slog.Warn("skip kustomization update", "dir", path, "err", err)
			return err
		}
		return nil
	}
}

// isKustomizationFile reports whether the given path is a kustomization file.
func isKustomizationFile(path string) bool {
	return filepath.Base(path) == "kustomization.yaml"
}

func updateKustomizationForDir(d string) error {
	root, err := yaml.ReadFile(filepath.Join(d, "kustomization.yaml"))
	if err != nil {
		return fmt.Errorf("read kustomization.yaml: %w", err)
	}

	imageAnnotationNode, err := root.Pipe(utils.GetImagesAnnotation())
	if err != nil {
		return fmt.Errorf("get images annotation: %w", err)
	}
	imageConfigs, err := utils.GetImagesConfig(imageAnnotationNode)
	if err != nil {
		return fmt.Errorf("get image config: %w", err)
	}
	imageConfigsByName := utils.CreateImageConfigsByName(imageConfigs)

	labelsNode, err := root.Pipe(yaml.Lookup("labels"))
	if err != nil {
		return fmt.Errorf("lookup labels: %w", err)
	}
	labelNodes, err := labelsNode.Elements()
	if err != nil {
		return fmt.Errorf("get labels pairs: %w", err)
	}
	var recoLabelName string
	for _, labelNode := range labelNodes {
		var valNode *yaml.RNode
		valNode, err = labelNode.Pipe(
			yaml.Lookup("pairs"),
			yaml.Get(utils.KubernetesNameLabel),
		)
		if err != nil {
			return fmt.Errorf("get %s: %w", utils.KubernetesNameLabel, err)
		}
		recoLabelName = yaml.GetValue(valNode)
	}

	imagesNode, err := root.Pipe(yaml.Lookup("images"))
	if err != nil {
		return fmt.Errorf("lookup images: %w", err)
	}
	imageNodes, err := imagesNode.Elements()
	if err != nil {
		return fmt.Errorf("get images elements: %w", err)
	}

	// Update image tags based on annotation configs
	for _, img := range imageNodes {
		nameNode, err := img.Pipe(yaml.Get("name"))
		if err != nil {
			slog.Warn("missing name in images entry", "dir", d, "err", err)
			continue
		}
		name := yaml.GetValue(nameNode)
		cfg, ok := imageConfigsByName[name]
		if !ok {
			continue
		}
		newNameNode, err := img.Pipe(yaml.Get("newName"))
		if err != nil {
			return fmt.Errorf("get newName for %s: %w", name, err)
		}

		options := []registry.FindLatestOption{}

		if len(cfg.ExcludeTags) > 0 {
			options = append(options, registry.WithExclude(cfg.ExcludeTags))
		}

		if cfg.TagRegex != nil {
			options = append(options, registry.WithTransform(cfg.TagRegex))
		}

		// Fetch raw tags
		tags, err := registry.ListTags(yaml.GetValue(newNameNode))
		if err != nil {
			return fmt.Errorf("list tags for %s: %w", name, err)
		}

		// Set base version if current newTag is a valid semver
		currentTagNode, err := img.Pipe(yaml.Get("newTag"))
		if err != nil {
			return fmt.Errorf("get current newTag for %s: %w", name, err)
		}
		currentTag := yaml.GetValue(currentTagNode)
		if currentTag != "" {
			var version string
			version, err = utils.ParseSemver(cfg.TagRegex, currentTag)
			if err != nil {
				return fmt.Errorf("parse semver for %s: %w", currentTag, err)
			}
			options = append(options, registry.WithBaseline(version))
		}

		latest, err := registry.FindLatestTag(tags, options...)
		if err != nil {
			continue
		}
		if latest == "" {
			slog.Info("no matching tag found", "dir", d, "image", name)
			return nil
		}
		if err = img.PipeE(yaml.SetField("newTag", yaml.NewStringRNode(latest))); err != nil {
			return fmt.Errorf("set newTag for %s: %w", name, err)
		}
		slog.Info("updated image tag", "dir", d, "name", name, "image", name, "tag", latest)

		if recoLabelName == name {
			var vers string
			if cfg.TagRegex != nil {
				vers, err = utils.ParseSemver(cfg.TagRegex, latest)
				if err != nil {
					return fmt.Errorf("parse semver for %s: %w", latest, err)
				}
			} else {
				vers = latest
			}
			if err = root.PipeE(utils.SetRecommandedLabels(name, vers)); err != nil {
				return fmt.Errorf("set %s: %w", utils.KubernetesVersionLabel, err)
			}
			slog.Info("updated recommended labels", "dir", d, "name", name, "image", name, "tag", latest)
		}
	}

	if err := yaml.WriteFile(root, filepath.Join(d, "kustomization.yaml")); err != nil {
		return fmt.Errorf("write kustomization.yaml: %w", err)
	}

	return nil
}
