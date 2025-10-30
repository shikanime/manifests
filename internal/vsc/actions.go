package vsc

import (
	"fmt"
	"strings"
)

type GitHubActionRef struct {
	Owner   string
	Repo    string
	Version string
}

func (a GitHubActionRef) String() string {
	return fmt.Sprintf("%s/%s@%s", a.Owner, a.Repo, a.Version)
}

// ParseGitHubActionRef parses a GitHub Actions `uses` string like "owner/repo@v1".
func ParseGitHubActionRef(uses string) (ref *GitHubActionRef, err error) {
	s := strings.TrimSpace(uses)
	if s == "" {
		return nil, fmt.Errorf("empty uses")
	}
	parts := strings.Split(s, "@")
	if len(parts) != 2 {
		return nil, fmt.Errorf("invalid uses: missing '@'")
	}
	path := strings.TrimSpace(parts[0])
	version := strings.TrimSpace(parts[1])
	if path == "" || version == "" {
		return nil, fmt.Errorf("invalid uses: empty action or version")
	}
	pathParts := strings.Split(path, "/")
	if len(pathParts) != 2 || strings.TrimSpace(pathParts[0]) == "" || strings.TrimSpace(pathParts[1]) == "" {
		return nil, fmt.Errorf("invalid action path %q, expected <owner>/<repo>", path)
	}
	return &GitHubActionRef{Owner: pathParts[0], Repo: pathParts[1], Version: version}, nil
}
