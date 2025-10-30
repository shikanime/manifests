package app

import (
	"fmt"
	"log/slog"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/shikanime/manifests/internal/utils"
	"github.com/spf13/cobra"
)

// UpdateScriptCmd runs all update.sh scripts found under the provided directory.
var UpdateScriptCmd = &cobra.Command{
	Use:   "updatescript [DIR]",
	Short: "Run all update.sh scripts",
	RunE: func(cmd *cobra.Command, args []string) error {
		root := "."
		if len(args) > 0 && strings.TrimSpace(args[0]) != "" {
			root = args[0]
		}
		return runUpdateScript(root)
	},
}

// runUpdateScript walks the directory tree starting at root and executes every update.sh found.
func runUpdateScript(root string) error {
	var scripts []string
	err := utils.WalkDirWithGitignore(root, func(path string, d os.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			return nil
		}
		if filepath.Base(path) == "update.sh" {
			scripts = append(scripts, path)
		}
		return nil
	})
	if err != nil {
		return fmt.Errorf("scan for update.sh: %w", err)
	}

	if len(scripts) == 0 {
		slog.Info("no update.sh scripts found", "root", root)
		return nil
	}

	for _, script := range scripts {
		dir := filepath.Dir(script)
		slog.Info("running update script", "script", script)
		cmd := exec.Command("bash", "update.sh")
		cmd.Dir = dir
		cmd.Env = os.Environ()

		out, runErr := cmd.CombinedOutput()
		if len(out) > 0 {
			slog.Info("update.sh output", "script", script, "output", string(out))
		}
		if runErr != nil {
			slog.Warn("update.sh failed", "script", script, "error", runErr)
			return fmt.Errorf("run %s: %w", script, runErr)
		}
		slog.Info("update script completed", "script", script)
	}

	return nil
}
