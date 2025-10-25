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
		image           = "docker.io/gitea/gitea"
		name            = "gitea"
		dir             = "apps/gitea/base"
		labelKey        = "" // omit to skip label updates
		tagRegex        = `^\d+\.\d+\.\d+$`
		excludeTagsCSV  = ""
		labelTrimPrefix = ""
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
	// Sort by major, minor, patch in descending order (highest version first)
	sort.Slice(vals, func(i, j int) bool {
		a, b := vals[i].parts, vals[j].parts

		// Compare major, minor, patch parts in order
		maxLen := len(a)
		if len(b) > maxLen {
			maxLen = len(b)
		}

		for k := 0; k < maxLen; k++ {
			// Get version part (default to 0 if not present)
			aPart := 0
			bPart := 0
			if k < len(a) {
				aPart = a[k]
			}
			if k < len(b) {
				bPart = b[k]
			}

			// If parts are different, sort in descending order (higher version first)
			if aPart != bPart {
				return aPart > bPart
			}
		}
		return false
	})
	return vals[0].tag, nil
}
