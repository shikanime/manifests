package app

import (
	"fmt"
	"io/fs"
	"log"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/spf13/cobra"
	"gopkg.in/yaml.v3"
)

var UpdateKustomizationVersionCmd = &cobra.Command{
	Use:   "version",
	Short: "Sync app.kubernetes.io/version label from images[*].newTag matching app.kubernetes.io/name",
	RunE: func(cmd *cobra.Command, args []string) error {
		root := "."
		if len(args) > 0 && strings.TrimSpace(args[0]) != "" {
			root = args[0]
		}
		return filepath.WalkDir(root, func(path string, d fs.DirEntry, walkErr error) error {
			if walkErr != nil {
				return walkErr
			}
			if d.IsDir() {
				return nil
			}
			if filepath.Base(path) != "kustomization.yaml" {
				return nil
			}

			subdir := filepath.Dir(path)
			if err := updateVersionForDir(subdir); err != nil {
				log.Printf("Skip %s: %v\n", subdir, err)
			}
			return nil
		})
	},
}

func updateVersionForDir(d string) error {
	k, configs, err := loadKustomizationAndConfigs(d)
	if err != nil {
		return err
	}

	cfgByName := make(map[string]ImageConfig, len(configs))
	for _, c := range configs {
		cfgByName[c.Name] = c
	}

	appName := ""
	for _, l := range k.Labels {
		if val, ok := l.Pairs["app.kubernetes.io/name"]; ok && val != "" {
			appName = val
			break
		}
	}
	if appName == "" {
		return fmt.Errorf("app.kubernetes.io/name not found in labels")
	}

	newTag := ""
	for _, img := range k.Images {
		if img.Name == appName {
			newTag = img.NewTag
			break
		}
	}
	if newTag == "" {
		return fmt.Errorf("no images entry with name=%q and non-empty newTag", appName)
	}

	cfg, ok := cfgByName[appName]
	if !ok || strings.TrimSpace(cfg.TagRegex) == "" {
		return fmt.Errorf("no tag-regex in annotation for image %q", appName)
	}
	re, err := regexp.Compile(cfg.TagRegex)
	if err != nil {
		return fmt.Errorf("invalid tag-regex %q: %w", cfg.TagRegex, err)
	}
	sem, err := parseSemver(re, newTag)
	if err != nil {
		return fmt.Errorf("normalize version from tag %q: %w", newTag, err)
	}
	normalized := strings.TrimPrefix(sem, "v")

	currentVersion := ""
	for _, l := range k.Labels {
		if val, ok := l.Pairs["app.kubernetes.io/version"]; ok {
			currentVersion = val
			break
		}
	}
	if currentVersion == normalized {
		log.Printf("[%s] Version already up to date: %s\n", d, normalized)
		return nil
	}

	if err := runYQSetLabel(d, "app.kubernetes.io/version", normalized); err != nil {
		return fmt.Errorf("yq set label: %w", err)
	}
	log.Printf("[%s] Updated app.kubernetes.io/version to %s (app=%s, tag=%s)\n", d, normalized, appName, newTag)

	data, err := os.ReadFile(filepath.Join(d, "kustomization.yaml"))
	if err == nil {
		var k2 Kustomization
		if yaml.Unmarshal(data, &k2) == nil {
			// Parsed successfully
		}
	}
	return nil
}
