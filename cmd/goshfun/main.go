// Command goshfun exposes functions from named packages in the Go standard
// library by generating a single standalone executable capable of calling each
// discovered function directly from the command line.
package main

import (
	"flag"
	"fmt"
	"go/build"
	"path/filepath"

	"github.com/ardnew/gosh/cmd/goshfun/pkg"
	"github.com/ardnew/gosh/cmd/goshfun/run"

	"github.com/ardnew/version"
)

func init() {
	version.ChangeLog = []version.Change{
		{ // initializing project version number in ONE location is fine I guess
			Package: "goshfun",
			Version: "0.1.0",
			Date:    "July 7, 2020",
			Description: []string{
				`initial commit`,
			},
		}, {
			Package: "goshfun",
			Version: "0.1.1",
			Date:    "January 22, 2021",
			Description: []string{
				`add math/bits as default package`,
				`refactor output, include goimports install tip`,
				`change default output name: fun`,
			},
		},
	}
}

const (
	defaultName = "fun"
	defaultSyms = "gosh"
)

func main() {

	var (
		argChanges bool
		argVersion bool
		argRoot    string
		argPkg     pkg.Pkg
		argOut     string
		argSym     string
	)

	outputName := defaultName
	outputSyms := filepath.Join(defaultName, defaultSyms)

	flag.BoolVar(&argChanges, "changelog", false, "display change history")
	flag.BoolVar(&argVersion, "version", false, "display version information")
	flag.StringVar(&argRoot, "root", build.Default.GOROOT, "path to GOROOT (must contain src)")
	flag.Var(&argPkg, "pkg", "generate interfaces for functions from package `path`. may be specified multiple times. (default \"strings\",\"math\",\"math/bits\",\"path/filepath\")")
	flag.StringVar(&argOut, "out", outputName, "name of the output directory and generated executable")
	flag.StringVar(&argSym, "sym", outputSyms, "path to install generated symlinks (or do not generate if empty)")
	flag.Parse()

	if argChanges {
		version.PrintChangeLog()
	} else if argVersion {
		fmt.Printf("goshfun version %s\n", version.String())
	} else {
		// main
		run.Run(argRoot, argOut, argSym, argPkg)
	}
}
