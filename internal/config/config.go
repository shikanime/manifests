package config

import (
	"log/slog"
	"os"
)

// GetLogLevel returns the logging level from `LOG_LEVEL`.
// Valid values: "debug", "info", "warn", "error"; defaults to "info".
func GetLogLevel() slog.Level {
	switch os.Getenv("LOG_LEVEL") {
	case "debug":
		return slog.LevelDebug
	case "info":
		return slog.LevelInfo
	case "warn":
		return slog.LevelWarn
	case "error":
		return slog.LevelError
	default:
		return slog.LevelInfo
	}
}

// GetGithubToken returns the GitHub personal access token from GITHUB_TOKEN.
// It returns an empty string if the variable is not set.
func GetGithubToken() string {
	return os.Getenv("GITHUB_TOKEN")
}
