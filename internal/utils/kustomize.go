package utils

import (
	"encoding/json"
	"fmt"
	"regexp"
	"strings"

	"sigs.k8s.io/kustomize/kyaml/yaml"
)

const (
	// ImagesAnnotation is the kustomize annotation key that stores image
	// configuration in JSON, used to control tag selection and update strategy.
	ImagesAnnotation = "automata.shikanime.studio/images"

	// KubernetesNameLabel is the recommended Kubernetes label key for the app
	// name, applied to kustomization labels pairs.
	KubernetesNameLabel = "app.kubernetes.io/name"

	// KubernetesVersionLabel is the recommended Kubernetes label key for the app
	// version, applied to kustomization labels pairs.
	KubernetesVersionLabel = "app.kubernetes.io/version"
)

// GetImagesAnnotation returns a kyaml filter that retrieves the images
// configuration annotation (ImagesAnnotation) from a kustomization.
func GetImagesAnnotation() yaml.Filter {
	return yaml.GetAnnotation(ImagesAnnotation)
}

// ImagesEntrySetter sets fields on an existing images[] item matched by name.
// Creates the images sequence if missing; skips if the item doesn't exist.
type ImagesEntrySetter struct {
	Name    string `yaml:"name,omitempty"`
	NewName string `yaml:"newName,omitempty"`
	NewTag  string `yaml:"newTag,omitempty"`
}

func (s ImagesEntrySetter) Filter(rn *yaml.RNode) (*yaml.RNode, error) {
	images, err := rn.Pipe(yaml.PathGetter{
		Path: []string{"images"}, Create: yaml.MappingNode,
	})
	if err != nil || yaml.IsMissingOrNull(images) {
		return rn, err
	}
	if s.Name != "" {
		if err := images.PipeE(
			yaml.MatchElement("name", s.Name),
			yaml.SetField("name", yaml.NewStringRNode(s.Name))); err != nil {
			return rn, err
		}
	}
	if s.NewName != "" {
		if err := images.PipeE(
			yaml.MatchElement("name", s.Name),
			yaml.SetField("newName", yaml.NewStringRNode(s.NewName))); err != nil {
			return rn, err
		}
	}
	if s.NewTag != "" {
		if err := images.PipeE(
			yaml.MatchElement("name", s.Name),
			yaml.SetField("newTag", yaml.NewStringRNode(s.NewTag))); err != nil {
			return rn, err
		}
	}
	return rn, nil
}

// SetImage returns an ImagesEntrySetter that sets the name/newName/newTag fields
// on a matching item in the images[] section of a kustomization.
// SetImage returns a setter to update name/newName/newTag in images[].
func SetImage(name, newName, newTag string) ImagesEntrySetter {
	return ImagesEntrySetter{Name: name, NewName: newName, NewTag: newTag}
}

// RecommandedLabelsSetter updates the labels[].pairs[labelKey] in kustomization.yaml.
// It updates the first labels entry's pairs map. If labels or pairs do not
// exist, it skips.
type RecommandedLabelsSetter struct {
	Name    string `yaml:"name,omitempty"`
	Version string `yaml:"version,omitempty"`
}

func (s RecommandedLabelsSetter) Filter(rn *yaml.RNode) (*yaml.RNode, error) {
	labelsNode, err := rn.Pipe(yaml.Lookup("labels"))
	if err != nil {
		return rn, fmt.Errorf("lookup labels: %w", err)
	}
	labelNodes, err := labelsNode.Elements()
	if err != nil {
		return rn, fmt.Errorf("get labels elements: %w", err)
	}
	for _, labelNode := range labelNodes {
		if err := labelNode.PipeE(
			yaml.Lookup("pairs"),
			yaml.SetField("app.kubernetes.io/name", yaml.NewStringRNode(s.Name))); err != nil {
			return rn, fmt.Errorf("set label %s: %w", "app.kubernetes.io/name", err)
		}
		if err := labelNode.PipeE(
			yaml.Lookup("pairs"),
			yaml.SetField("app.kubernetes.io/version", yaml.NewStringRNode(s.Version))); err != nil {
			return rn, fmt.Errorf("set label %s: %w", "app.kubernetes.io/version", err)
		}
	}
	return rn, nil
}

// SetRecommandedLabels returns a setter to update recommended name/version labels.
func SetRecommandedLabels(name, version string) RecommandedLabelsSetter {
	return RecommandedLabelsSetter{Name: name, Version: version}
}

// StrategyType controls how new tags are chosen relative to a baseline.
type StrategyType int

const (
	// FullUpdate: any greater version.
	FullUpdate StrategyType = iota
	// MinorUpdate: same major.
	MinorUpdate
	// PatchUpdate: same major.minor.
	PatchUpdate
)

// ImagesConfig configures image tag selection and update strategy.
type ImagesConfig struct {
	Name         string
	TagRegex     *regexp.Regexp
	ExcludeTags  map[string]struct{}
	StrategyType StrategyType
}

// UnmarshalJSON parses ImagesConfig from annotation JSON.
func (c *ImagesConfig) UnmarshalJSON(data []byte) error {
	var raw struct {
		Name         string   `json:"name"`
		TagRegex     string   `json:"tag-regex"`
		ExcludeTags  []string `json:"exclude-tags"`
		StrategyType string   `json:"update-strategy"`
	}
	if err := json.Unmarshal(data, &raw); err != nil {
		return err
	}

	c.Name = raw.Name

	if raw.TagRegex != "" {
		re, err := regexp.Compile(raw.TagRegex)
		if err != nil {
			return fmt.Errorf("invalid tag-regex %q: %w", raw.TagRegex, err)
		}
		c.TagRegex = re
	} else {
		c.TagRegex = nil
	}

	if len(raw.ExcludeTags) > 0 {
		m := make(map[string]struct{}, len(raw.ExcludeTags))
		for _, e := range raw.ExcludeTags {
			m[e] = struct{}{}
		}
		c.ExcludeTags = m
	} else {
		c.ExcludeTags = nil
	}

	// Parse update strategy
	if raw.StrategyType != "" {
		switch strings.ToLower(raw.StrategyType) {
		case "FullUpdate":
			c.StrategyType = FullUpdate
		case "MinorUpdate":
			c.StrategyType = MinorUpdate
		case "PatchUpdate":
			c.StrategyType = PatchUpdate
		default:
			return fmt.Errorf("invalid update-strategy %q: must be one of 'Full', 'Minor', 'Patch'", raw.StrategyType)
		}
	}

	return nil
}

// GetImagesConfig extracts image configs from an annotation node.
func GetImagesConfig(node *yaml.RNode) ([]ImagesConfig, error) {
	if yaml.IsMissingOrNull(node) {
		return nil, nil
	}
	var imageConfigs []ImagesConfig
	if err := json.Unmarshal([]byte(node.YNode().Value), &imageConfigs); err != nil {
		return nil, fmt.Errorf("unmarshal ImageConfig from annotation: %w", err)
	}
	return imageConfigs, nil
}

// CreateImageConfigsByName maps image name to its configuration.
func CreateImageConfigsByName(imageConfigs []ImagesConfig) map[string]ImagesConfig {
	cfgByName := make(map[string]ImagesConfig, len(imageConfigs))
	for _, c := range imageConfigs {
		cfgByName[c.Name] = c
	}
	return cfgByName
}
