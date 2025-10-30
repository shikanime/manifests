package utils

import (
	"os/exec"
)

func IsGitIgnored(root, path string) bool {
	cmd := exec.Command("git", "check-ignore", "-q", "--", path)
	cmd.Dir = root
	if err := cmd.Run(); err == nil {
		return true
	}
	return false
}
