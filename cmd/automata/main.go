package main

import (
	"log/slog"
	"os"

	"github.com/shikanime/manifests/cmd/automata/app"
	"github.com/spf13/cobra"
)

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
