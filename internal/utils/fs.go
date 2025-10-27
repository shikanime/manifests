package utils

import (
	"io/fs"
	"os/exec"
	"path/filepath"
)

func isGitIgnored(path, repoDir string) bool {
	cmd := exec.Command("git", "check-ignore", "-q", "--", path)
	cmd.Dir = repoDir
	if err := cmd.Run(); err == nil {
		return true
	}
	return false
}

func WalkDirWithGitignore(root string, fn fs.WalkDirFunc) error {
	return filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if isGitIgnored(path, root) {
			if d.IsDir() {
				return fs.SkipDir
			}
			return nil
		}
		return fn(path, d, err)
	})
}
