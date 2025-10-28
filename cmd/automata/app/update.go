package app

import (
	"strings"

	"github.com/spf13/cobra"
	"golang.org/x/sync/errgroup"
)

var all bool

var UpdateCmd = &cobra.Command{
	Use:   "update [DIR]",
	Short: "Update resources",
	RunE: func(cmd *cobra.Command, args []string) error {
		if !all {
			return cmd.Help()
		}
		root := "."
		if len(args) > 0 && strings.TrimSpace(args[0]) != "" {
			root = args[0]
		}

		g := new(errgroup.Group)
		g.Go(func() error {
			return runUpdateKustomization(root)
		})
		g.Go(func() error {
			return runUpdateSops(root)
		})
		return g.Wait()
	},
}

func init() {
	UpdateCmd.Flags().BoolVar(&all, "all", false, "Run all update operations")
	UpdateCmd.AddCommand(UpdateKustomizationCmd)
	UpdateCmd.AddCommand(UpdateSopsCmd)
}
