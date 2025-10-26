package app

import "os/exec"

// isGitIgnored returns true if git reports the path as ignored.
// If git is not available or the directory is not a repo, it returns false.
func isGitIgnored(path, repoDir string) bool {
	cmd := exec.Command("git", "check-ignore", "-q", "--", path)
	cmd.Dir = repoDir
	if err := cmd.Run(); err == nil {
		return true
	}
	return false
}
