// Command goshfun exposes functions from named packages in the Go standard
// library by generating a single standalone executable capable of calling each
// discovered function directly from the command line.
package main

import (
	"flag"
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
		},
	}
}

const outputName = "gof"

var outputSyms = "gosh"

func main() {

	var (
		argRoot string
		argPkg  pkg.Pkg
		argOut  string
		argSym  string
	)

	outputSyms = filepath.Join(outputName, outputSyms)

	flag.StringVar(&argRoot, "root", build.Default.GOROOT, "path to GOROOT (must contain src)")
	flag.Var(&argPkg, "pkg", "generate interfaces for functions from package `path`. may be specified multiple times. (default \"strings\",\"math\",\"path/filepath\")")
	flag.StringVar(&argOut, "out", outputName, "name of the generated executable")
	flag.StringVar(&argSym, "sym", outputSyms, "path to install generated symlinks (or do not generate if empty)")
	flag.Parse()

	run.Run(argRoot, argOut, argSym, argPkg)
}
