package app

import (
	"encoding/json"
	"fmt"

	"sigs.k8s.io/kustomize/kyaml/yaml"
)

const (
	ImagesAnnotation       = "automata.shikanime.studio/images"
	KubernetesNameLabel    = "app.kubernetes.io/name"
	KubernetesVersionLabel = "app.kubernetes.io/version"
)

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

func SetRecommandedLabels(name, version string) RecommandedLabelsSetter {
	return RecommandedLabelsSetter{Name: name, Version: version}
}

type ImageConfig struct {
	Name        string   `json:"name"`
	TagRegex    string   `json:"tag-regex"`
	ExcludeTags []string `json:"exclude-tags,omitempty"`
}

func GetImageConfig(node *yaml.RNode) ([]ImageConfig, error) {
	if yaml.IsMissingOrNull(node) {
		return nil, nil
	}
	var imageConfigs []ImageConfig
	if err := json.Unmarshal([]byte(node.YNode().Value), &imageConfigs); err != nil {
		return nil, fmt.Errorf("unmarshal ImageConfig from annotation: %w", err)
	}
	return imageConfigs, nil
}

func CreateImageConfigsByName(imageConfigs []ImageConfig) map[string]ImageConfig {
	cfgByName := make(map[string]ImageConfig, len(imageConfigs))
	for _, c := range imageConfigs {
		cfgByName[c.Name] = c
	}
	return cfgByName
}
