package app

import "github.com/spf13/cobra"

var UpdateCmd = &cobra.Command{
	Use:   "update",
	Short: "Update resources",
}

func init() {
	UpdateCmd.AddCommand(UpdateKustomizationCmd)
	UpdateCmd.AddCommand(UpdateSopsCmd)
}
