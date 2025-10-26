package app

import (
	"fmt"
	"io/fs"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/spf13/cobra"
)

var UpdateSopsCmd = &cobra.Command{
	Use:   "sops [DIR]",
	Short: "Encrypt plaintext files to .enc.* when outdated",
	RunE: func(cmd *cobra.Command, args []string) error {
		root := "."
		if len(args) > 0 && strings.TrimSpace(args[0]) != "" {
			root = args[0]
		}
		up := &SopsUpdater{Dir: root}
		return up.Update()
	},
}

type SopsUpdater struct {
	Dir string
}

func (su *SopsUpdater) Update() error {
	if su.Dir == "" {
		return fmt.Errorf("dir is required")
	}
	return filepath.WalkDir(su.Dir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		// Respect .gitignore: skip ignored files/dirs
		if isGitIgnored(path, su.Dir) {
			if d.IsDir() {
				return fs.SkipDir
			}
			return nil
		}
		if d.IsDir() {
			return nil
		}

		base := filepath.Base(path)
		if !strings.Contains(base, ".enc.") {
			return nil
		}

		plainBase := strings.Replace(base, ".enc.", ".", 1)
		plainPath := filepath.Join(filepath.Dir(path), plainBase)

		plainInfo, err := os.Stat(plainPath)
		if err != nil {
			return nil
		}

		encInfo, err := os.Stat(path)
		needsEncrypt := false
		if err != nil && os.IsNotExist(err) {
			needsEncrypt = true
		} else if err != nil {
			return err
		} else if encInfo.ModTime().Before(plainInfo.ModTime()) {
			needsEncrypt = true
		}

		if !needsEncrypt {
			return nil
		}

		if err := runSopsEncrypt(plainPath, path); err != nil {
			return fmt.Errorf("sops encrypt %s -> %s: %w", plainPath, path, err)
		}
		log.Printf("Encrypted %s to %s\n", plainPath, path)
		return nil
	})
}

func runSopsEncrypt(plainPath, encPath string) error {
	out, err := os.Create(encPath)
	if err != nil {
		return err
	}
	defer out.Close()

	cmd := exec.Command("sops", "--encrypt", plainPath)
	cmd.Stdout = out
	cmd.Stderr = log.Writer()
	return cmd.Run()
}
