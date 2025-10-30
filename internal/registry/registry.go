package registry

import (
	"fmt"
	"log/slog"
	"regexp"

	"github.com/google/go-containerregistry/pkg/authn"
	"github.com/google/go-containerregistry/pkg/crane"
	"github.com/shikanime/manifests/internal/utils"
)

// ListTags fetches tags for the given image (auth keychain, fallback anonymous).
func ListTags(imageRef *ImageRef) ([]string, error) {
	// Try with keychain, then fallback to anonymous; forward any provided crane options.
	tags, err := crane.ListTags(
		imageRef.String(),
		crane.WithAuthFromKeychain(authn.DefaultKeychain),
	)
	if err != nil {
		slog.Debug("list tags with keychain failed, falling back to anonymous", "image", imageRef.String(), "err", err)
		tags, err = crane.ListTags(
			imageRef.Name,
			crane.WithAuth(authn.Anonymous),
		)
		if err != nil {
			slog.Error("list tags failed", "image", imageRef.String(), "err", err)
			return nil, err
		}
	}
	return tags, nil
}

// FindLatestOption configures how FindLatestTag filters and selects a tag,
// including exclusions, update strategy, transforms, and baseline.
type FindLatestOption func(*findLatestOptions)

type findLatestOptions struct {
	exclude           map[string]struct{}
	updateStrategy    utils.StrategyType
	transformRegex    *regexp.Regexp
	includePreRelease bool
}

// WithExclude sets the exclusion list for tags. Any tag present in the map
// will be ignored when selecting the latest tag.
func WithExclude(exclude map[string]struct{}) FindLatestOption {
	return func(o *findLatestOptions) {
		o.exclude = exclude
	}
}

// WithStrategyType sets the tag update strategy (full, minor-only, patch-only)
// used by FindLatestTag relative to the baseline.
func WithStrategyType(strategy utils.StrategyType) FindLatestOption {
	return func(o *findLatestOptions) {
		o.updateStrategy = strategy
	}
}

// WithTransform sets a regular expression used to extract and normalize the
// semver from raw tags when computing the latest tag.
func WithTransform(re *regexp.Regexp) FindLatestOption {
	return func(o *findLatestOptions) {
		o.transformRegex = re
	}
}

// WithPreRelease enables inclusion of prerelease and build metadata tags
// in the tag selection process.
func WithPreRelease(include bool) FindLatestOption {
	return func(o *findLatestOptions) {
		o.includePreRelease = include
	}
}

// FindLatestTag returns the latest tag for the given image based on the provided options.
func FindLatestTag(imageRef *ImageRef, opts ...FindLatestOption) (string, error) {
	o := &findLatestOptions{updateStrategy: utils.FullUpdate}
	for _, opt := range opts {
		opt(o)
	}

	// Baseline from the current action version
	baselineSem, err := utils.ParseSemver(imageRef.Tag)
	if err != nil {
		return "", fmt.Errorf("invalid baseline %q: %w", imageRef.Tag, err)
	}

	// Determine baseline according to update strategy
	var baseline string
	switch o.updateStrategy {
	case utils.FullUpdate:
		baseline = baselineSem
	case utils.MinorUpdate:
		baseline = utils.Major(baselineSem)
	case utils.PatchUpdate:
		baseline = utils.MajorMinor(baselineSem)
	default:
		baseline = baselineSem
	}

	tags, err := ListTags(imageRef)
	if err != nil {
		return "", fmt.Errorf("list tags: %w", err)
	}

	bestTag := ""
	for _, t := range tags {
		// Skip any non-valid semver
		var sem string
		if o.transformRegex != nil {
			sem, err = utils.ParseSemverWithRegex(o.transformRegex, t)
			if err != nil {
				slog.Debug("non-semver tag ignored", "tag", t, "err", err)
				continue
			}
		} else {
			sem, err = utils.ParseSemver(t)
			if err != nil {
				slog.Debug("non-semver tag ignored", "tag", t, "err", err)
				continue
			}
		}

		// Prerelease tags are skipped if not explicitly included
		if !o.includePreRelease {
			if utils.PreRelease(sem) != "" {
				slog.Debug("prerelease tag ignored", "tag", t, "sem", sem)
				continue
			}
		}

		// Apply exclusion filter
		if _, ok := o.exclude[t]; ok {
			slog.Debug("tag excluded by exclude filter", "tag", t, "sem", sem)
			continue
		}

		// Apply update strategy filtering when baseline is set via WithCurrentVersion
		if utils.Compare(sem, baseline) <= 0 {
			continue
		}
		switch o.updateStrategy {
		case utils.MinorUpdate:
			if utils.Major(sem) == baseline {
				bestTag = t
			} else {
				slog.Debug("tag excluded by update strategy", "tag", t, "sem", sem, "baseline", baseline)
			}
		case utils.PatchUpdate:
			if utils.MajorMinor(sem) == baseline {
				bestTag = t
			} else {
				slog.Debug("tag excluded by update strategy", "tag", t, "sem", sem, "baseline", baseline)
			}
		default:
			bestTag = t
		}
	}

	return bestTag, nil
}
