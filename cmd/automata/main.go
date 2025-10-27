// Package main is the entrypoint for the Automata CLI, wiring commands and
// global configuration such as logging.
package main

import (
	"log/slog"
	"os"

	"github.com/shikanime/manifests/cmd/automata/app"
	"github.com/shikanime/manifests/internal/config"
	"github.com/spf13/cobra"
)

func init() {
	slog.SetDefault(slog.New(slog.NewJSONHandler(
		os.Stderr,
		&slog.HandlerOptions{Level: config.GetLogLevel()},
	)))
}

func main() {
	rootCmd := &cobra.Command{
		Use:   "automata",
		Short: "Automata CLI",
	}
	rootCmd.AddCommand(app.UpdateCmd)
	if err := rootCmd.Execute(); err != nil {
		slog.Error("command execution failed", "error", err)
		os.Exit(1)
	}
}
