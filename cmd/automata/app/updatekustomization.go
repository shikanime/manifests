package app

import (
	"fmt"
	"io/fs"
	"log/slog"
	"path/filepath"
	"strings"

	"github.com/spf13/cobra"
	"golang.org/x/mod/semver"
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
		if err := WalkDirWithGitignore(root, func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if d.IsDir() {
				return nil
			}
			if !isKustomizationFile(path) {
				return nil
			}
			g.Go(func(dir string) func() error {
				return func() error {
					if err := updateKustomizationForDir(dir); err != nil {
						slog.Warn("skip kustomization update", "dir", dir, "err", err)
						return err
					}
					return nil
				}
			}(filepath.Dir(path)))
			return nil
		}); err != nil {
			return err
		}
		return g.Wait()
	},
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

	imageAnnotationNode, err := root.Pipe(GetImagesAnnotation())
	if err != nil {
		return fmt.Errorf("get images annotation: %w", err)
	}
	imageConfigs, err := GetImagesConfig(imageAnnotationNode)
	if err != nil {
		return fmt.Errorf("get image config: %w", err)
	}
	imageConfigsByName := CreateImageConfigsByName(imageConfigs)

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
			yaml.Get(KubernetesNameLabel),
		)
		if err != nil {
			return fmt.Errorf("get %s: %w", KubernetesNameLabel, err)
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

		options := []FindLatestOption{}

		if len(cfg.ExcludeTags) > 0 {
			options = append(options, WithExclude(cfg.ExcludeTags))
		}

		if cfg.TagRegex != nil {
			options = append(options, WithTransform(cfg.TagRegex))
		}

		// Fetch raw tags
		tags, err := listTags(yaml.GetValue(newNameNode))
		if err != nil {
			return fmt.Errorf("list tags for %s: %w", name, err)
		}

		// Set base version if current newTag is a valid semver
		currentTagNode, err := img.Pipe(yaml.Get("newTag"))
		if err != nil {
			return fmt.Errorf("get current newTag for %s: %w", name, err)
		}
		currentTag := yaml.GetValue(currentTagNode)
		if currentTag != "" && semver.IsValid(currentTag) {
			options = append(options, WithBaseline(currentTag))
		}

		latest, err := findLatestTag(tags, options...)
		if err != nil {
			return fmt.Errorf("fetch latest tag for %s: %w", name, err)
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
				vers, err = parseSemver(cfg.TagRegex, latest)
				if err != nil {
					return fmt.Errorf("parse semver for %s: %w", latest, err)
				}
			} else {
				vers = latest
			}
			if err = root.PipeE(SetRecommandedLabels(name, vers)); err != nil {
				return fmt.Errorf("set %s: %w", KubernetesVersionLabel, err)
			}
			slog.Info("updated recommended labels", "dir", d, "name", name, "image", name, "tag", latest)
		}
	}

	if err := yaml.WriteFile(root, filepath.Join(d, "kustomization.yaml")); err != nil {
		return fmt.Errorf("write kustomization.yaml: %w", err)
	}

	return nil
}
