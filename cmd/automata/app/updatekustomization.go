package app

import (
	"fmt"
	"io/fs"
	"log/slog"
	"path/filepath"
	"regexp"
	"sort"
	"strings"

	"github.com/google/go-containerregistry/pkg/authn"
	"github.com/google/go-containerregistry/pkg/crane"
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

// listTags lists tags for an image using the local keychain, falling back to anonymous.
func listTags(image string) ([]string, error) {
	tags, err := crane.ListTags(
		image,
		crane.WithAuthFromKeychain(authn.DefaultKeychain),
	)
	if err == nil {
		return tags, nil
	}
	tags, err = crane.ListTags(
		image,
		crane.WithAuth(authn.Anonymous),
	)
	if err != nil {
		return nil, fmt.Errorf("list tags: %w", err)
	}
	return tags, nil
}

// parseSemver extracts and validates a semver string from tag using named groups.
// It returns the canonical semver (with leading 'v') or an error if parsing fails.
func parseSemver(re *regexp.Regexp, tag string) (string, error) {
	m := re.FindStringSubmatch(tag)
	if m == nil {
		return "", fmt.Errorf("no semver match in tag %q", tag)
	}

	versionIdx := re.SubexpIndex("version")
	majorIdx := re.SubexpIndex("major")
	minorIdx := re.SubexpIndex("minor")
	patchIdx := re.SubexpIndex("patch")
	prereleaseIdx := re.SubexpIndex("prerelease")
	buildIdx := re.SubexpIndex("build")

	vers := ""
	if versionIdx >= 0 && versionIdx < len(m) && m[versionIdx] != "" {
		vers = m[versionIdx]
	} else if majorIdx >= 0 && minorIdx >= 0 && patchIdx >= 0 &&
		majorIdx < len(m) && minorIdx < len(m) && patchIdx < len(m) &&
		m[majorIdx] != "" && m[minorIdx] != "" && m[patchIdx] != "" {
		vers = m[majorIdx] + "." + m[minorIdx] + "." + m[patchIdx]
		if prereleaseIdx >= 0 && prereleaseIdx < len(m) && m[prereleaseIdx] != "" {
			vers += "-" + m[prereleaseIdx]
		}
		if buildIdx >= 0 && buildIdx < len(m) && m[buildIdx] != "" {
			vers += "+" + m[buildIdx]
		}
	} else {
		return "", fmt.Errorf("no version groups matched in tag %q", tag)
	}

	// Normalize to semver with leading 'v' (required by golang.org/x/mod/semver)
	if strings.HasPrefix(vers, "V") {
		vers = "v" + vers[1:]
	} else if !strings.HasPrefix(vers, "v") {
		vers = "v" + vers
	}

	if !semver.IsValid(vers) {
		return "", fmt.Errorf("invalid semver %q", vers)
	}
	return semver.Canonical(vers), nil
}

// helper to fetch latest tag with regex and exclusions
func getLatestTag(image, tagRegex string, exclude []string) (string, error) {
	tags, err := listTags(image)
	if err != nil {
		return "", err
	}

	excl := make(map[string]struct{}, len(exclude))
	for _, e := range exclude {
		excl[e] = struct{}{}
	}
	re, err := regexp.Compile(tagRegex)
	if err != nil {
		return "", fmt.Errorf("invalid tag-regex %q: %w", tagRegex, err)
	}

	type candidate struct {
		tag string
		sem string
	}

	vals := make([]candidate, 0, 64)
	for _, t := range tags {
		if _, skip := excl[t]; skip {
			continue
		}
		sem, err := parseSemver(re, t)
		if err != nil {
			// Skip non-matching or invalid semver tags
			continue
		}
		vals = append(vals, candidate{
			tag: t,
			sem: sem,
		})
	}

	if len(vals) == 0 {
		return "", nil
	}

	sort.Slice(vals, func(i, j int) bool {
		return semver.Compare(vals[i].sem, vals[j].sem) > 0
	})
	return vals[0].tag, nil
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
	imageConfigs, err := GetImageConfig(imageAnnotationNode)
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
		if !ok || cfg.TagRegex == "" {
			continue
		}
		newNameNode, err := img.Pipe(yaml.Get("newName"))
		if err != nil {
			return fmt.Errorf("get newName for %s: %w", name, err)
		}
		latest, err := getLatestTag(yaml.GetValue(newNameNode), cfg.TagRegex, cfg.ExcludeTags)
		if err != nil {
			return fmt.Errorf("fetch latest tag for %s: %w", name, err)
		}
		if latest == "" {
			slog.Info("no matching tag found", "dir", d, "image", name, "regex", cfg.TagRegex)
			continue
		}
		if err = img.PipeE(yaml.SetField("newTag", yaml.NewStringRNode(latest))); err != nil {
			return fmt.Errorf("set newTag for %s: %w", name, err)
		}
		slog.Info("updated image tag", "dir", d, "name", name, "image", name, "tag", latest)
		if recoLabelName == name {
			vers, err := parseSemver(regexp.MustCompile(cfg.TagRegex), latest)
			if err != nil {
				return fmt.Errorf("parse semver for %s: %w", latest, err)
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
