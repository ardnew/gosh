package run

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/ardnew/gosh/cmd/goshfun/parse"
	"github.com/ardnew/gosh/cmd/goshfun/pkg"
	"github.com/ardnew/gosh/cmd/goshfun/print"
	// "github.com/juju/errors"
)

// pkgDefault defines which Go standard library packages to generate supporting
// interfaces for if the -pkg flag is not provided.
var pkgDefault = pkg.Pkg{
	"math",
	"math/bits",
	"path/filepath",
	"regexp",
	"strings",
}

// Run is the primary program entry point which calls the parser, the printer,
// and finally the compiler to build the executable.
func Run(root, out, sym string, p pkg.Pkg) {

	const srcRoot, srcMain = "src", "main.go"

	// use the default packages if none were specified
	if len(p) == 0 {
		p = append(p, pkgDefault...)
	}

	// path to Go sources
	rootPath := filepath.Join(root, srcRoot)

	// parse sources, gathering all supported function prototypes
	pkgs, err := p.Parse(rootPath)
	if err != nil {
		panic(err)
	}

	// create generated output source file
	srcFile, srcPath := outputFile(out, srcMain)
	defer srcFile.Close()

	// generate the parsers/formatters source, pretty printed
	fmt.Printf("creating Go source file: %s\n", srcPath)
	prt := print.NewPrinter(srcFile, rootPath)
	prt.PrintHeader(pkgs)
	prt.PrintBody()
	for path, pkg := range pkgs {
		prt.PrintPackage(false, path, pkg)
	}

	// run goimports to clean up imports and format the resulting source code
	fmt.Printf("running goimports: %s\n", srcPath)
	goimports, err := execCmd(out, "goimports", "-w", srcMain)
	if nil != err {
		fmt.Printf("error: goimports: %v\n", err)
		fmt.Printf("tip: make sure goimports is installed (and in your PATH):\n")
		fmt.Printf("	go get -v golang.org/x/tools/cmd/goimports\n")
		os.Exit(2)
	} else if len(goimports) > 0 {
		fmt.Printf("%s\n", goimports)
	}

	// compile the resulting source code into a command-line executable
	fmt.Printf("running go build: %s\n", srcPath)
	gobuild, err := execCmd(out, "go", "build", "-o", out, srcMain)
	if nil != err {
		fmt.Printf("error: go build: %v\n", err)
		os.Exit(3)
	} else if len(gobuild) > 0 {
		fmt.Printf("%s\n", gobuild)
	}

	binPath := filepath.Join(out, out)
	fmt.Printf("done! executable created: %s\n", binPath)

	if "" != sym {
		fmt.Printf("creating symlinks to executable: %s\n", sym)
		outputSymlinks(srcPath, binPath, sym, pkgs)
	}
}

func outputFile(dir, name string) (*os.File, string) {
	if err := os.MkdirAll(dir, 0o777); nil != err {
		panic(err)
	}
	path := filepath.Join(dir, name)
	file, err := os.Create(path)
	if err != nil {
		panic(err)
	}
	return file, path
}

func outputSymlinks(src, bin, sym string, pkgs map[string]*parse.Package) {
	if err := os.RemoveAll(sym); nil != err {
		panic(err)
	}
	if err := os.MkdirAll(sym, 0o777); nil != err {
		panic(err)
	}
	for path, pkg := range pkgs {
		name := string([]rune(strings.TrimPrefix(path, src))[1:])
		for _, fun := range pkg.Func {
			ld := filepath.Join(sym, fun.ImportedName(name))

			if ls, err := filepath.Rel(sym, bin); nil != err {
				panic(err)
			} else if err := os.Symlink(ls, ld); nil != err {
				panic(err)
			}
		}
	}
}

func execCmd(dir, cmd string, arg ...string) ([]byte, error) {
	c := exec.Command(cmd, arg...)
	c.Dir = dir
	return c.CombinedOutput()
}
