package main

import (
	"log/slog"
	"os"
	"strings"

	"github.com/shikanime/manifests/cmd/automata/app"
	"github.com/spf13/cobra"
)

func main() {
	// Configure slog level based on environment variable
	setupLogging()

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

func setupLogging() {
	level := slog.LevelInfo

	if envLevel := os.Getenv("LOG_LEVEL"); envLevel != "" {
		switch strings.ToUpper(envLevel) {
		case "DEBUG":
			level = slog.LevelDebug
		case "INFO":
			level = slog.LevelInfo
		case "WARN", "WARNING":
			level = slog.LevelWarn
		case "ERROR":
			level = slog.LevelError
		}
	}

	opts := &slog.HandlerOptions{
		Level: level,
	}

	handler := slog.NewTextHandler(os.Stderr, opts)
	logger := slog.New(handler)
	slog.SetDefault(logger)
}
