package app

import (
	"fmt"
	"log/slog"
	"regexp"
	"sort"

	"github.com/google/go-containerregistry/pkg/authn"
	"github.com/google/go-containerregistry/pkg/crane"
	"golang.org/x/mod/semver"
)

// listTags fetches tags for the given image.
func listTags(image string) ([]string, error) {
	// Try with keychain, then fallback to anonymous; forward any provided crane options.
	tags, err := crane.ListTags(
		image,
		crane.WithAuthFromKeychain(authn.DefaultKeychain),
	)
	if err != nil {
		slog.Debug("list tags with keychain failed, falling back to anonymous", "image", image, "err", err)
		tags, err = crane.ListTags(
			image,
			crane.WithAuth(authn.Anonymous),
		)
		if err != nil {
			slog.Error("list tags failed", "image", image, "err", err)
			return nil, err
		}
	}
	return tags, nil
}

type FindLatestOption func(*findLatestOptions)

type UpdateStrategy int

const (
	UpdateAll UpdateStrategy = iota
	UpdateMinor
	UpdatePatch
)

type findLatestOptions struct {
	exclude        map[string]struct{}
	updateStrategy UpdateStrategy
	transformRegex *regexp.Regexp
	baseline       string
}

func WithExclude(exclude map[string]struct{}) FindLatestOption {
	return func(o *findLatestOptions) {
		o.exclude = exclude
	}
}

func WithUpdateStrategy(strategy UpdateStrategy) FindLatestOption {
	return func(o *findLatestOptions) {
		o.updateStrategy = strategy
	}
}

func WithTransform(re *regexp.Regexp) FindLatestOption {
	return func(o *findLatestOptions) {
		o.transformRegex = re
	}
}

func WithBaseline(version string) FindLatestOption {
	return func(o *findLatestOptions) {
		o.baseline = version
	}
}

// helper to fetch latest tag; applies transform (regex), sorts tags by semver (desc),
// applies update strategy relative to the optional baseline from WithCurrentVersion,
// then returns the first non-excluded tag.
func findLatestTag(tags []string, opts ...FindLatestOption) (string, error) {
	o := &findLatestOptions{updateStrategy: UpdateAll, baseline: "v0.1.0"}
	for _, opt := range opts {
		opt(o)
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
			v, err := parseSemver(o.transformRegex, t)
			if err != nil {
				slog.Debug("non-semver tag ignored", "tag", t, "err", err)
				continue
			}
			sem = v
		} else {
			sem = semver.Canonical(t)
			if !semver.IsValid(sem) {
				slog.Debug("non-semver tag ignored", "tag", t, "sem", sem)
				continue
			}
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
		if semver.Compare(c.sem, o.baseline) <= 0 {
			continue
		}
		switch o.updateStrategy {
		case UpdateMinor:
			if semver.Major(c.sem) == semver.Major(o.baseline) {
				tagsWithBaseline = append(tagsWithBaseline, c)
			} else {
				slog.Debug("tag excluded by update strategy", "tag", c.tag, "sem", c.sem, "baseline", o.baseline)
			}
		case UpdatePatch:
			if semver.MajorMinor(c.sem) == semver.MajorMinor(o.baseline) {
				tagsWithBaseline = append(tagsWithBaseline, c)
			} else {
				slog.Debug("tag excluded by update strategy", "tag", c.tag, "sem", c.sem, "baseline", o.baseline)
			}
		default:
			tagsWithBaseline = append(tagsWithBaseline, c)
		}
	}

	// Sort descending by semver
	sort.Slice(tagsWithBaseline, func(i, j int) bool {
		return semver.Compare(tagsWithBaseline[i].sem, tagsWithBaseline[j].sem) > 0
	})

	// Return the first non-excluded tag after all filtering
	if len(tagsWithBaseline) > 0 {
		return tagsWithBaseline[0].tag, nil
	}
	return "", fmt.Errorf("no suitable tag found")
}
