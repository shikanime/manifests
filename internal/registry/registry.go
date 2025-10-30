package registry

import (
	"fmt"
	"log/slog"
	"regexp"
	"sort"

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
			imageRef.String(),
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
	exclude        map[string]struct{}
	updateStrategy utils.StrategyType
	transformRegex *regexp.Regexp
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

// FindLatestTag returns the latest tag for the given image based on the provided options.
func FindLatestTag(imageRef *ImageRef, opts ...FindLatestOption) (string, error) {
	o := &findLatestOptions{updateStrategy: utils.FullUpdate}
	for _, opt := range opts {
		opt(o)
	}

	tags, err := ListTags(imageRef)
	if err != nil {
		return "", fmt.Errorf("list tags: %w", err)
	}

	baselineSem, err := utils.ParseSemver(imageRef.Tag)
	if err != nil {
		return "", fmt.Errorf("invalid baseline %q: %w", imageRef.Tag, err)
	}

	type candidate struct {
		tag string
		sem string
	}

	// Build candidates; skip any non-valid semver
	validTags := make([]candidate, 0, len(tags))
	for _, t := range tags {
		var sem string
		if o.transformRegex != nil {
			v, err := utils.ParseSemverWithRegex(o.transformRegex, t)
			if err != nil {
				slog.Debug("non-semver tag ignored", "tag", t, "err", err)
				continue
			}
			sem = v
		} else {
			v, err := utils.ParseSemver(t)
			if err != nil {
				slog.Debug("non-semver tag ignored", "tag", t, "err", err)
				continue
			}
			sem = v
		}
		validTags = append(validTags, candidate{tag: t, sem: sem})
	}

	// Apply exclusion filter
	tagsWithExclude := make([]candidate, 0, len(validTags))
	for _, c := range validTags {
		if _, ok := o.exclude[c.tag]; !ok {
			tagsWithExclude = append(tagsWithExclude, c)
		}
	}

	// Apply update strategy filtering when baseline is set via WithCurrentVersion
	tagsWithBaseline := make([]candidate, 0, len(tagsWithExclude))
	for _, c := range tagsWithExclude {
		if utils.Compare(c.sem, baselineSem) <= 0 {
			continue
		}
		switch o.updateStrategy {
		case utils.MinorUpdate:
			major, err := utils.Major(c.sem)
			if err != nil {
				slog.Debug("tag excluded by update strategy", "tag", c.tag, "sem", c.sem, "baseline", baselineSem, "err", err)
				continue
			}
			baselineMajor, err := utils.Major(baselineSem)
			if err != nil {
				slog.Debug("tag excluded by update strategy", "tag", c.tag, "sem", c.sem, "baseline", baselineSem, "err", err)
				continue
			}
			if major == baselineMajor {
				tagsWithBaseline = append(tagsWithBaseline, c)
			} else {
				slog.Debug("tag excluded by update strategy", "tag", c.tag, "sem", c.sem, "baseline", baselineSem)
			}
		case utils.PatchUpdate:
			majorMinor, err := utils.MajorMinor(c.sem)
			if err != nil {
				slog.Debug("tag excluded by update strategy", "tag", c.tag, "sem", c.sem, "baseline", baselineSem, "err", err)
				continue
			}
			baselineMajorMinor, err := utils.MajorMinor(baselineSem)
			if err != nil {
				slog.Debug("tag excluded by update strategy", "tag", c.tag, "sem", c.sem, "baseline", baselineSem, "err", err)
				continue
			}
			if majorMinor == baselineMajorMinor {
				tagsWithBaseline = append(tagsWithBaseline, c)
			} else {
				slog.Debug("tag excluded by update strategy", "tag", c.tag, "sem", c.sem, "baseline", baselineSem)
			}
		default:
			tagsWithBaseline = append(tagsWithBaseline, c)
		}
	}

	// Sort descending by semver
	sort.Slice(tagsWithBaseline, func(i, j int) bool {
		return utils.Compare(tagsWithBaseline[i].sem, tagsWithBaseline[j].sem) > 0
	})

	// Return the first non-excluded tag after all filtering
	if len(tagsWithBaseline) > 0 {
		return tagsWithBaseline[0].tag, nil
	}
	return "", fmt.Errorf("no suitable tag found")
}
