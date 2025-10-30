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

// FindLatestMajorTag returns the original tag name of the highest pure major (vN)
// for a GitHub action repository in the form "owner/repo". If none is found, returns "".
func (gc *GitHubClient) FindLatestMajorTag(ctx context.Context, action *GitHubActionRef) (string, error) {
	bestMajor := ""
	bestTagName := ""

	tags, _, err := gc.c.Repositories.ListTags(ctx, action.Owner, action.Repo, nil)
	if err != nil {
		return "", fmt.Errorf("github list tags: %w", err)
	}
	for _, t := range tags {
		if t.Name == nil {
			continue
		}
		raw := *t.Name
		if raw == "" {
			continue
		}

		// Canonicalize via utils; skip invalid semvers
		canon, err := utils.ParseSemver(raw)
		if err != nil || canon == "" {
			continue
		}

		major, err := utils.Major(canon)
		if err != nil {
			continue
		}
		// Only consider pure major tags (e.g., v1, v2)
		if major != canon {
			continue
		}

		if bestMajor == "" || utils.Compare(major, bestMajor) > 0 {
			bestMajor = major
			// Return original repo tag text, preserving casing/format
			bestTagName = raw
		}
	}

	return bestTagName, nil
}
