// busygo exposes functions from the Go standard library through a single
// standalone executable for individual use directly from the command line.
package main

import (
	"flag"
	"fmt"
	"go/build"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/ardnew/gosh/cmd/goshfun/pkg"
	"github.com/ardnew/gosh/cmd/goshfun/print"
	// "github.com/juju/errors"
)

const outputName = "fun"

// May be overridden using -pkg flags. Provide the -pkg flag multiple times to
// specify multiple packages (e.g. "-pkg 'the/first' -pkg 'the/second' ...").
//
// pkgDefault defines which Go standard library packages to generate supporting
// interfaces for if the -pkg flag is not provided.
var pkgDefault = pkg.Pkg{
	"math",
	"path/filepath",
	"strings",
}

func main() {

	var (
		argRoot string
		argPkg  pkg.Pkg
		argOut  string
	)

	flag.StringVar(&argRoot, "root", build.Default.GOROOT, "path to GOROOT (must contain src)")
	flag.Var(&argPkg, "pkg", "generate interfaces for functions from package `path`. may be specified multiple times. (default \"strings\",\"path/filepath\")")
	flag.StringVar(&argOut, "out", outputPath(), "generated Go source will be written to file `dir`/main.go")
	flag.Parse()

	// use the default packages if none were specified
	if len(argPkg) == 0 {
		argPkg = append(argPkg, pkgDefault...)
	}

	// path to Go sources
	srcPath := filepath.Join(argRoot, "src")

	// parse sources, gathering all supported function prototypes
	pkgs, err := argPkg.Parse(srcPath)
	if err != nil {
		panic(err)
	}

	// create generated output source file
	file := mkOutputFile(argOut, "main.go")
	defer file.Close()

	outputFilePath := filepath.Join(argOut, "main.go")
	outputBinPath := filepath.Join(argOut, argOut)

	// generate the parsers/formatters source, pretty printed
	fmt.Printf("---\ncreating Go source file: %s\n", outputFilePath)
	prt := print.NewPrinter(file, srcPath)
	prt.PrintHeader(pkgs)
	prt.PrintBody()
	for path, pkg := range pkgs {
		prt.PrintPackage(true, path, pkg)
	}

	fmt.Printf("---\nrunning goimports: %s\n", outputFilePath)
	goimports := execCmd(argOut, "goimports", "-w", "main.go")
	if len(goimports) > 0 {
		fmt.Printf("%s\n", goimports)
	}

	fmt.Printf("---\nrunning go build: %s\n", outputFilePath)
	gobuild := execCmd(argOut, "go", "build")
	if len(gobuild) > 0 {
		fmt.Printf("%s\n", gobuild)
	}

	fmt.Printf("---\ndone: executable created: %s\n", outputBinPath)
}

func outputPath() string { return filepath.Join(".", outputName) }
func mkOutputFile(dir, name string) *os.File {
	if err := os.MkdirAll(dir, 0o777); nil != err {
		panic(err)
	}
	path := filepath.Join(dir, name)
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	return file
}

func execCmd(dir, cmd string, arg ...string) []byte {
	c := exec.Command(cmd, arg...)
	c.Dir = dir
	o, err := c.CombinedOutput()
	if nil != err {
		panic(err)
	}
	return o
}
