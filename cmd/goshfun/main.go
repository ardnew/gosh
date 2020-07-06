// busygo exposes functions from the Go standard library through a single
// standalone executable for individual use directly from the command line.
package main

import (
	"flag"
	"fmt"
	"go/build"
	"os"
	"path/filepath"

	"github.com/ardnew/gosh/cmd/goshfun/pkg"
	"github.com/ardnew/gosh/cmd/goshfun/print"
	// "github.com/juju/errors"
)

// May be overridden using -pkg flags. Provide the -pkg flag multiple times to
// specify multiple packages (e.g. "-pkg 'the/first' -pkg 'the/second' ...").

// pkgDefault defines which Go standard library packages to generate supporting
// interfaces for if the -pkg flag is not provided.
var pkgDefault = pkg.Pkg{
	"strings",
	"path/filepath",
}

func main() {

	var (
		argRoot string
		argPkg  pkg.Pkg
	)

	flag.StringVar(&argRoot, "root", build.Default.GOROOT, "path to GOROOT (must contain src)")
	flag.Var(&argPkg, "pkg", "generate interfaces for functions from package `path`. may be specified multiple times. (default \"strings\",\"path/filepath\")")
	flag.Parse()

	if len(argPkg) == 0 {
		argPkg = append(argPkg, pkgDefault...)
	}

	srcPath := filepath.Join(argRoot, "src")

	if pack, err := argPkg.Parse(srcPath); err == nil {
		for p, pkg := range pack {
			print.NewPrinter(os.Stdout, srcPath, p).Print(pkg)
		}
	} else {
		fmt.Printf("error: %+v\n", err)
	}
}
