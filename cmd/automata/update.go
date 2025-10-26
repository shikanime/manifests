package main

import (
	"fmt"
	"log"
	"os/exec"
	"regexp"
	"sort"
	"strings"

	"github.com/google/go-containerregistry/pkg/authn"
	"github.com/google/go-containerregistry/pkg/crane"
	"github.com/spf13/cobra"
	"golang.org/x/mod/semver"
)

func NewUpdateCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "update",
		Short: "Update resources",
	}
	cmd.AddCommand(NewUpdateKustomizationCmd())
	return cmd
}

func NewUpdateKustomizationCmd() *cobra.Command {
	var (
		image          = "docker.io/gitea/gitea"
		name           = "gitea"
		dir            = "apps/gitea/base"
		labelKey       = ""
		tagRegex       = `(?i)(?:v)?(?P<major>\d+)\.(?P<minor>\d+)\.(?P<patch>\d+)(?:-(?P<prerelease>[0-9A-Za-z.-]+))?(?:\+(?P<build>[0-9A-Za-z.-]+))?`
		excludeTagsCSV = ""
	)

	cmd := &cobra.Command{
		Use:   "kustomization",
		Short: "Update kustomize image tag and labels",
		RunE: func(cmd *cobra.Command, args []string) error {
			var exclude []string
			if excludeTagsCSV != "" {
				exclude = strings.Split(excludeTagsCSV, ",")
				for i := range exclude {
					exclude[i] = strings.TrimSpace(exclude[i])
				}
			}

			latest, err := getLatestTag(image, tagRegex, exclude)
			if err != nil {
				return fmt.Errorf("fetch latest tag: %w", err)
			}
			if latest == "" {
				return fmt.Errorf("no matching tag found for %s", image)
			}

			if err := runKustomizeSetImage(dir, name, image, latest); err != nil {
				return fmt.Errorf("kustomize set image: %w", err)
			}

			if labelKey != "" {
				re, err := regexp.Compile(tagRegex)
				if err != nil {
					return fmt.Errorf("invalid tag-regex %q: %w", tagRegex, err)
				}
				sem, err := parseSemver(re, latest)
				if err != nil {
					return fmt.Errorf("parse label from tag %q: %w", latest, err)
				}
				labelVal := strings.TrimPrefix(sem, "v")

				if err := runYQSetLabel(dir, labelKey, labelVal); err != nil {
					return fmt.Errorf("yq set label: %w", err)
				}
				log.Printf("Updated %s to %s:%s and label %s=%s\n", name, image, latest, labelKey, labelVal)
			} else {
				log.Printf("Updated %s to %s:%s\n", name, image, latest)
			}

			return nil
		},
	}

	cmd.Flags().StringVar(&image, "image", image, "Full image reference (e.g. docker.io/org/name)")
	cmd.Flags().StringVar(&name, "name", name, "Kustomize image name")
	cmd.Flags().StringVar(&dir, "dir", dir, "Target directory containing kustomization.yaml")
	cmd.Flags().StringVar(&labelKey, "label-key", labelKey, "Label key to set to the image version (omit to skip)")
	cmd.Flags().StringVar(&tagRegex, "tag-regex", tagRegex, "Regex with named capture 'version' to select tags (SemVer core with optional prerelease/build)")
	cmd.Flags().StringVar(&excludeTagsCSV, "exclude-tags", excludeTagsCSV, "Comma-separated list of tags to exclude")

	return cmd
}

// run kustomize edit set image "<name>=<image>:<tag>" in <dir>
func runKustomizeSetImage(dir, name, image, tag string) error {
	cmd := exec.Command("kustomize", "edit", "set", "image", fmt.Sprintf("%s=%s:%s", name, image, tag))
	cmd.Dir = dir
	cmd.Stdout = log.Writer()
	cmd.Stderr = log.Writer()
	return cmd.Run()
}

// run YQ to set version label inside kustomization.yaml in <dir>
func runYQSetLabel(dir, labelKey, tag string) error {
	expr := fmt.Sprintf(`.labels.[].pairs.["%s"] = "%s"`, labelKey, tag)
	cmd := exec.Command("yq", "-i", expr, "kustomization.yaml")
	cmd.Dir = dir
	cmd.Stdout = log.Writer()
	cmd.Stderr = log.Writer()
	return cmd.Run()
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

// KustomizeUpdater encapsulates updating image tags and labels for a kustomization.
type KustomizeUpdater struct {
	Image    string
	Name     string
	Dir      string
	LabelKey string
	TagRegex string
	Exclude  []string
}

// Update fetches the latest valid semver tag, updates kustomization image and optional label.
func (ku *KustomizeUpdater) Update() error {
	latest, err := getLatestTag(ku.Image, ku.TagRegex, ku.Exclude)
	if err != nil {
		return fmt.Errorf("fetch latest tag: %w", err)
	}
	if latest == "" {
		return fmt.Errorf("no matching tag found for %s", ku.Image)
	}

	if err := runKustomizeSetImage(ku.Dir, ku.Name, ku.Image, latest); err != nil {
		return fmt.Errorf("kustomize set image: %w", err)
	}

	if ku.LabelKey != "" {
		re, err := regexp.Compile(ku.TagRegex)
		if err != nil {
			return fmt.Errorf("invalid tag-regex %q: %w", ku.TagRegex, err)
		}
		sem, err := parseSemver(re, latest)
		if err != nil {
			return fmt.Errorf("parse label from tag %q: %w", latest, err)
		}
		labelVal := strings.TrimPrefix(sem, "v")

		if err := runYQSetLabel(ku.Dir, ku.LabelKey, labelVal); err != nil {
			return fmt.Errorf("yq set label: %w", err)
		}
		log.Printf("Updated %s to %s:%s and label %s=%s\n", ku.Name, ku.Image, latest, ku.LabelKey, labelVal)
	} else {
		log.Printf("Updated %s to %s:%s\n", ku.Name, ku.Image, latest)
	}

	return nil
}
