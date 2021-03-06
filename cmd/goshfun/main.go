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
				`+ Initial commit`,
			},
		}, {
			Package: "goshfun",
			Version: "0.1.1",
			Date:    "January 22, 2021",
			Description: []string{
				`+ Add math/bits as default package`,
				`+ Refactor output, include goimports install tip`,
				`% Change default output name: fun`,
			},
		}, {
			Package: "goshfun",
			Version: "0.1.2",
			Date:    "March 6, 2021",
			Description: []string{
				`+ Add regexp as default package`,
				`% Fix build command for compatibility with modules-enabled Go (1.16)`,
				`- Move go.mod file to root package path github.com/ardnew/gosh`,
				`% Rename command-line flags to simpler, abbreviated form:`,
				`    -r=-root -p=-pkg -o=-out -s=-sym -v=-version -V=-changelog  (new=old)`,
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

	flag.BoolVar(&argChanges, "V", false, "display change history")
	flag.BoolVar(&argVersion, "v", false, "display version information")
	flag.StringVar(&argRoot, "r", build.Default.GOROOT, "path to GOROOT (must contain src)")
	flag.Var(&argPkg, "p", "generate interfaces for functions from package `path`. may be specified multiple times. (default \"strings\",\"math\",\"math/bits\",\"path/filepath\",\"regexp\")")
	flag.StringVar(&argOut, "o", outputName, "name of the output directory and generated executable")
	flag.StringVar(&argSym, "s", outputSyms, "path to install generated symlinks (or do not generate if empty)")
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
