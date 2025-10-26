package app

import (
	"encoding/json"
	"fmt"
	"io/fs"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"

	"github.com/google/go-containerregistry/pkg/authn"
	"github.com/google/go-containerregistry/pkg/crane"
	"github.com/spf13/cobra"
	"golang.org/x/mod/semver"
	"gopkg.in/yaml.v3"
)

var (
	labelKey = ""
)

var UpdateKustomizationCmd = &cobra.Command{
	Use:   "kustomization [DIR]",
	Short: "Update kustomize image tags",
	RunE: func(cmd *cobra.Command, args []string) error {
		root := "."
		if len(args) > 0 && strings.TrimSpace(args[0]) != "" {
			root = args[0]
		}

		return filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if d.IsDir() {
				return nil
			}
			if filepath.Base(path) != "kustomization.yaml" {
				return nil
			}
			subdir := filepath.Dir(path)
			if err := updateKustomization(subdir); err != nil {
				log.Printf("Skip %s: %v\n", subdir, err)
			}
			return nil
		})
	},
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

const annotationKey = "automata.config.shikanime.studio/images"

type Kustomization struct {
	Metadata struct {
		Annotations map[string]string `yaml:"annotations"`
	} `yaml:"metadata"`
	Labels []struct {
		Pairs map[string]string `yaml:"pairs"`
	} `yaml:"labels"`
	Images []struct {
		Name    string `yaml:"name"`
		NewName string `yaml:"newName"`
		NewTag  string `yaml:"newTag"`
	} `yaml:"images"`
}

type ImageConfig struct {
	Name     string   `json:"name"`
	TagRegex string   `json:"tag-regex"`
	Exclude  []string `json:"exclude-tags,omitempty"`
}

func loadKustomizationAndConfigs(dir string) (*Kustomization, []ImageConfig, error) {
	path := filepath.Join(dir, "kustomization.yaml")
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, nil, fmt.Errorf("read kustomization.yaml: %w", err)
	}
	var k Kustomization
	if err := yaml.Unmarshal(data, &k); err != nil {
		return nil, nil, fmt.Errorf("parse kustomization.yaml: %w", err)
	}
	raw := ""
	if k.Metadata.Annotations != nil {
		raw = k.Metadata.Annotations[annotationKey]
	}
	if strings.TrimSpace(raw) == "" {
		return &k, nil, nil
	}
	var cfg []ImageConfig
	if err := json.Unmarshal([]byte(raw), &cfg); err != nil {
		return &k, nil, fmt.Errorf("parse annotation %s: %w", annotationKey, err)
	}
	return &k, cfg, nil
}

func updateKustomization(d string) error {
	k, configs, err := loadKustomizationAndConfigs(d)
	if err != nil {
		return err
	}
	cfgByName := make(map[string]ImageConfig, len(configs))
	for _, c := range configs {
		cfgByName[c.Name] = c
	}

	for _, img := range k.Images {
		cfg, ok := cfgByName[img.Name]
		if !ok || img.NewName == "" {
			// skip images without config or missing newName
			continue
		}
		latest, err := getLatestTag(img.NewName, cfg.TagRegex, cfg.Exclude)
		if err != nil {
			return fmt.Errorf("fetch latest tag for %s: %w", img.NewName, err)
		}
		if latest == "" {
			log.Printf("No matching tag found for %s with regex %q, skipping\n", img.NewName, cfg.TagRegex)
			continue
		}

		if err := runKustomizeSetImage(d, img.Name, img.NewName, latest); err != nil {
			return fmt.Errorf("kustomize set image for %s: %w", img.Name, err)
		}
		log.Printf("[%s] Updated %s to %s:%s\n", d, img.Name, img.NewName, latest)
	}
	return nil
}
