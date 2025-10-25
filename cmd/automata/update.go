package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os/exec"
	"regexp"
	"sort"
	"strconv"
	"strings"

	"github.com/spf13/cobra"
)

// NewUpdateCmd creates the 'update' subcommand for updating kustomize image tags
// and optionally setting a version label.
func NewUpdateCmd() *cobra.Command {
	var (
		image           = "docker.io/gitea/gitea"
		name            = "gitea"
		dir             = "apps/gitea/base"
		labelKey        = ""
		tagRegex        = `^\d+\.\d+\.\d+$`
		excludeTagsCSV  = ""
		labelTrimPrefix = ""
	)

	cmd := &cobra.Command{
		Use:   "update",
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

			labelVal := latest
			if labelTrimPrefix != "" && strings.HasPrefix(labelVal, labelTrimPrefix) {
				labelVal = strings.TrimPrefix(labelVal, labelTrimPrefix)
			}

			if err := runKustomizeSetImage(dir, name, image, latest); err != nil {
				return fmt.Errorf("kustomize set image: %w", err)
			}

			if labelKey != "" {
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
	cmd.Flags().StringVar(&tagRegex, "tag-regex", tagRegex, "Regex to select tags")
	cmd.Flags().StringVar(&excludeTagsCSV, "exclude-tags", excludeTagsCSV, "Comma-separated list of tags to exclude")
	cmd.Flags().StringVar(&labelTrimPrefix, "label-trim-prefix", labelTrimPrefix, "Prefix to trim from label value")

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

// helper to fetch latest tag with regex and exclusions
func getLatestTag(image, tagRegex string, exclude []string) (string, error) {
	type skopeoTags struct {
		Repository string   `json:"Repository"`
		Tags       []string `json:"Tags"`
	}

	out, err := exec.Command("skopeo", "list-tags", "docker://"+image).Output()
	if err != nil {
		return "", err
	}

	var tags skopeoTags
	if err = json.Unmarshal(out, &tags); err != nil {
		return "", err
	}

	excl := make(map[string]struct{}, len(exclude))
	for _, e := range exclude {
		excl[e] = struct{}{}
	}

	re, err := regexp.Compile(tagRegex)
	if err != nil {
		return "", fmt.Errorf("compile tag regex: %w", err)
	}

	type sortable struct {
		tag   string
		parts []int
	}
	vals := make([]sortable, 0, len(tags.Tags))

	splitRe := regexp.MustCompile(`[.\-]`)
	for _, t := range tags.Tags {
		if _, skip := excl[t]; skip {
			continue
		}
		if !re.MatchString(t) {
			continue
		}
		chunks := splitRe.Split(t, -1)
		ints := make([]int, len(chunks))
		for i, c := range chunks {
			v, err := strconv.Atoi(c)
			if err != nil {
				v = 0
			}
			ints[i] = v
		}
		vals = append(vals, sortable{tag: t, parts: ints})
	}

	if len(vals) == 0 {
		return "", nil
	}

	sort.Slice(vals, func(i, j int) bool {
		a, b := vals[i].parts, vals[j].parts
		n := len(a)
		if len(b) > n {
			n = len(b)
		}
		for k := 0; k < n; k++ {
			av := 0
			bv := 0
			if k < len(a) {
				av = a[k]
			}
			if k < len(b) {
				bv = b[k]
			}
			if av != bv {
				return av < bv
			}
		}
		return false
	})

	return vals[len(vals)-1].tag, nil
}
