package app

import "github.com/spf13/cobra"

var UpdateCmd = &cobra.Command{
	Use:   "update",
	Short: "Update resources",
}

var dir = "."

func init() {
	UpdateCmd.PersistentFlags().StringVar(
		&dir,
		"dir",
		dir,
		"Root directory for update operations",
	)

	UpdateCmd.AddCommand(UpdateKustomizationCmd)
	UpdateCmd.AddCommand(UpdateSopsCmd)
	UpdateCmd.AddCommand(UpdateKustomizationVersionCmd)
}
