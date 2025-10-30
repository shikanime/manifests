package utils

import (
	"io/fs"
	"os/exec"
	"path/filepath"
)

func IsGitIgnored(root, path string) bool {
	cmd := exec.Command("git", "check-ignore", "-q", "--", path)
	cmd.Dir = root
	if err := cmd.Run(); err == nil {
		return true
	}
	return false
}

// WalkDirWithGitignore walks `root` like `filepath.WalkDir`, skipping paths
// ignored by git (`git check-ignore`). Ignored directories are not descended.
func WalkDirWithGitignore(root string, fn fs.WalkDirFunc) error {
	return filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if IsGitIgnored(root, path) {
			if d.IsDir() {
				return fs.SkipDir
			}
			return nil
		}
		return fn(path, d, err)
	})
}
