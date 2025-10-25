package main

import (
	"log"

	"github.com/spf13/cobra"
)

func main() {
	// Cobra root and update command insertion
	rootCmd := &cobra.Command{
		Use:   "sixo",
		Short: "Sixo CLI",
	}

	// Register subcommands
	rootCmd.AddCommand(NewUpdateCmd())

	if err := rootCmd.Execute(); err != nil {
		log.Fatal(err)
	}
}
