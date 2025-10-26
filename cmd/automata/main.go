package main

import (
	"log"

	"github.com/spf13/cobra"
)

func main() {
	rootCmd := &cobra.Command{
		Use:   "sixo",
		Short: "Sixo CLI",
	}
	rootCmd.AddCommand(NewUpdateCmd())
	if err := rootCmd.Execute(); err != nil {
		log.Fatal(err)
	}
}
