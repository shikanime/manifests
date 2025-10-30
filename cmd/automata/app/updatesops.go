package app

import (
	"fmt"
	"io/fs"
	"log/slog"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/shikanime/manifests/internal/utils"
	"github.com/spf13/cobra"
	"golang.org/x/sync/errgroup"
)

// UpdateSopsCmd encrypts plaintext files to `.enc.` when missing or outdated.
var UpdateSopsCmd = &cobra.Command{
	Use:   "sops [DIR]",
	Short: "Encrypt plaintext files to .enc.* when outdated",
	RunE: func(cmd *cobra.Command, args []string) error {
		root := "."
		if len(args) > 0 && strings.TrimSpace(args[0]) != "" {
			root = args[0]
		}
		return runUpdateSops(root)
	},
}

// runUpdateSops executes sops encryption updates across the directory tree.
func runUpdateSops(root string) error {
	g := new(errgroup.Group)
	err := utils.WalkDirWithGitignore(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			return nil
		}
		if !isEncryptedFile(path) {
			return nil
		}
		base := filepath.Base(path)
		plainBase := strings.Replace(base, ".enc.", ".", 1)
		plainPath := filepath.Join(filepath.Dir(path), plainBase)
		shouldEncrypt, err := isEncryptNeeded(plainPath, path)
		if err != nil {
			return err
		}
		if !shouldEncrypt {
			return nil
		}
		g.Go(createSopsEncryptJob(plainPath, path))
		return nil
	})
	if err != nil {
		return err
	}
	return g.Wait()
}

// createSopsEncryptJob creates a task to encrypt one file pair.
func createSopsEncryptJob(plainPath, encPath string) func() error {
	return func() error {
		if err := runSopsEncrypt(plainPath, encPath); err != nil {
			return fmt.Errorf("sops encrypt %s -> %s: %w", plainPath, encPath, err)
		}
		slog.Info("sops encrypted file", "plain", plainPath, "enc", encPath)
		return nil
	}
}

// runSopsEncrypt writes `sops --encrypt` output from `plainPath` to `encPath`.
func runSopsEncrypt(plainPath, encPath string) error {
	out, err := os.Create(encPath)
	if err != nil {
		return err
	}
	defer out.Close()

	cmd := exec.Command("sops", "--encrypt", plainPath)
	cmd.Stdout = out
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

// isEncryptNeeded returns true when encrypted file is missing or older.
func isEncryptNeeded(plainPath, encPath string) (bool, error) {
	plainInfo, err := os.Stat(plainPath)
	if err != nil {
		// If plaintext doesn't exist or can't be stat'ed, skip encryption
		if os.IsNotExist(err) {
			return false, nil
		}
		return false, nil
	}

	encInfo, err := os.Stat(encPath)
	if err != nil && os.IsNotExist(err) {
		// Encrypted file missing: needs encryption
		return true, nil
	} else if err != nil {
		// Unexpected stat error: propagate
		return false, err
	}

	// Encrypt when encrypted file is older than plaintext
	return encInfo.ModTime().Before(plainInfo.ModTime()), nil
}

// isEncryptedFile checks for ".enc." in the base filename.
func isEncryptedFile(path string) bool {
	base := filepath.Base(path)
	return strings.Contains(base, ".enc.")
}
