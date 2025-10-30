package vsc

import (
	"context"
	"fmt"
	"log/slog"

	"github.com/google/go-github/v55/github"
	"github.com/shikanime/manifests/internal/utils"
	"golang.org/x/time/rate"
)

// GitHubClient wraps the go-github client with a rate limiter and datastore.
type GitHubClient struct {
	c *github.Client
	l *rate.Limiter
}

// GitHubClientOptions holds configuration for constructing a GitHubClient.
type GitHubClientOptions struct {
	token string
}

// GitHubClientOption mutates GitHubClientOptions.
type GitHubClientOption func(*GitHubClientOptions)

// WithAuthToken configures an OAuth token for authenticated GitHub requests.
func WithAuthToken(token string) GitHubClientOption {
	return func(o *GitHubClientOptions) { o.token = token }
}

// NewGitHubLimiter creates a new rate limiter for GitHub API calls.
// Authenticated: ~1.39 requests/second (5000/hour) with burst 10.
// Unauthenticated: 1 request/minute (60/hour) with burst 1.
func NewGitHubLimiter(authenticated bool) *rate.Limiter {
	if authenticated {
		limiter := rate.NewLimiter(rate.Limit(5000.0/3600.0), 10)
		slog.Info("Created authenticated GitHub rate limiter",
			"rate", "≈1.39 requests/second",
			"burst", 10)
		return limiter
	}
	limiter := rate.NewLimiter(rate.Limit(60.0/3600.0), 1)
	slog.Info("Created unauthenticated GitHub rate limiter",
		"rate", "1 request/minute",
		"burst", 1)
	return limiter
}

// NewGitHubClient creates a new GitHub client with optional authentication.
func NewGitHubClient(opts ...GitHubClientOption) *GitHubClient {
	var o GitHubClientOptions
	for _, opt := range opts {
		opt(&o)
	}

	if o.token != "" {
		slog.Info("Using authenticated GitHub client")
		return &GitHubClient{
			c: github.NewClient(nil).WithAuthToken(o.token),
			l: NewGitHubLimiter(true),
		}
	}

	slog.Warn("Using unauthenticated GitHub client (rate limited)")
	return &GitHubClient{
		c: github.NewClient(nil),
		l: NewGitHubLimiter(false),
	}
}

// FindLatestActionOption configures how FindLatestActionTag filters and selects a tag,
// including update strategy.
type FindLatestActionOption func(*findLatestActionOptions)

type findLatestActionOptions struct {
	updateStrategy    utils.StrategyType
	includePreRelease bool
}

// WithActionStrategyType sets the tag update strategy (full, minor-only, patch-only)
// used by FindLatestActionTag relative to the baseline action version.
func WithActionStrategyType(strategy utils.StrategyType) FindLatestActionOption {
	return func(o *findLatestActionOptions) {
		o.updateStrategy = strategy
	}
}

// WithPreRelease enables inclusion of prerelease and build metadata tags
// in the tag selection process.
func WithPreRelease(include bool) FindLatestActionOption {
	return func(o *findLatestActionOptions) {
		o.includePreRelease = include
	}
}

// FindLatestActionTag returns the latest tag for the given GitHub Action based on provided options.
func (gc *GitHubClient) FindLatestActionTag(ctx context.Context, action *GitHubActionRef, opts ...FindLatestActionOption) (string, error) {
	o := &findLatestActionOptions{updateStrategy: utils.FullUpdate}
	for _, opt := range opts {
		opt(o)
	}

	if err := gc.l.Wait(ctx); err != nil {
		return "", fmt.Errorf("rate limiter: %w", err)
	}

	// Baseline from the current action version
	baselineSem, err := utils.ParseSemver(action.Version)
	if err != nil {
		return "", fmt.Errorf("invalid baseline %q: %w", action.Version, err)
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

	tags, _, err := gc.c.Repositories.ListTags(ctx, action.Owner, action.Repo, nil)
	if err != nil {
		return "", fmt.Errorf("github list tags: %w", err)
	}

	bestTag := ""
	for _, t := range tags {
		// Skip any non-valid semver
		var sem string
		sem, err = utils.ParseSemver(*t.Name)
		if err != nil {
			slog.Debug("non-semver tag ignored", "tag", *t.Name, "err", err)
			continue
		}

		// Prerelease tags are skipped if not explicitly included
		if !o.includePreRelease {
			if utils.PreRelease(sem) != "" {
				slog.Debug("prerelease tag ignored", "tag", *t.Name, "sem", sem)
				continue
			}
		}

		// Only consider tags strictly greater than baseline
		if utils.Compare(sem, baseline) <= 0 {
			continue
		}
		switch o.updateStrategy {
		case utils.MinorUpdate:
			if utils.Major(sem) == baseline {
				bestTag = sem
			} else {
				slog.Debug("tag excluded by update strategy", "tag", *t.Name, "sem", sem, "baseline", baseline)
			}
		case utils.PatchUpdate:
			if utils.MajorMinor(sem) == baseline {
				bestTag = sem
			} else {
				slog.Debug("tag excluded by update strategy", "tag", *t.Name, "sem", sem, "baseline", baseline)
			}
		default:
			bestTag = sem
		}
	}

	return bestTag, nil
}
