package pkg

import (
	"fmt"
	"go/ast"
	"go/build"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"strings"
	"unicode"

	"github.com/ardnew/gosh/cmd/goshfun/parse"
	"github.com/juju/errors"
)

// Pkg represents packages to parse and generate interfaces for.
type Pkg []string

// String constructs a descriptive representation of a Pkg.
func (p *Pkg) String() string {

	q := []string{}
	for _, s := range *p {
		q = append(q, fmt.Sprintf("%q", s))
	}
	return fmt.Sprintf("[%s]", strings.Join(q, ", "))
}

// Set implements the flag.Value interface to parse packages from -pkg flags.
func (p *Pkg) Set(value string) error {

	// basic sanity tests, not spec-correct
	validPackageRune := func(c rune) bool {
		return unicode.IsLetter(c) || unicode.IsDigit(c) || c == '/'
	}
	validPackage := func(s string) bool {
		if len(s) > 0 && s[0] == '/' {
			return false // cannot start with slash
		}
		for _, c := range s {
			if !validPackageRune(c) {
				return false
			}
		}
		return true
	}

	if strings.TrimSpace(value) == "" {
		return fmt.Errorf("(empty)")
	} else if !validPackage(value) {
		return fmt.Errorf("package name: %q", value)
	}

	for _, k := range *p {
		if k == value {
			return fmt.Errorf("duplicate name: %q", value)
		}
	}

	*p = append(*p, value)

	return nil
}

// withPrefix prepends each path in the package list with the given prefix
// strings, returning the resulting slice of strings.
func (p *Pkg) withPrefix(prefix ...string) []string {

	q := []string{}
	x := filepath.Join(prefix...)
	for _, s := range *p {
		q = append(q, filepath.Join(x, s))
	}
	return q
}

// Parse constructs a list of Package located in a common GOROOT source parent
// directory, parsing (via AST construction) lists of exported function
// signatures/definitions associated with each said Package, and returns a list
// of each populated with all exported function signatures discovered.
func (p *Pkg) Parse(prefix ...string) (map[string]*parse.Package, error) {

	// we currently only support types with primitive bases (slices, ellipses, or
	// pointers to any of these are OK too)
	var primitive = []string{
		"bool", "byte", "rune", "string",
		"int", "int8", "int16", "int32", "int64",
		"uint", "uint8", "uint16", "uint32", "uint64",
		"uintptr",
		"float32", "float64",
		"complex64", "complex128",
	}

	path := p.withPrefix(prefix...)
	for _, dir := range path {
		if _, isDir := fileExists(dir); !isDir {
			return nil, errors.Errorf("invalid package source directory: %q", dir)
		}
	}

	pack := map[string]*parse.Package{}

	for _, dir := range path {

		// use ImportDir to filter the allowable files to the current Go compiler
		// build Context's GOOS, GOARCH, etc. This takes care of filtering by file
		// name as well as the build constraints defined in source file comments.
		pkg, err := build.Default.ImportDir(dir, build.ImportComment)
		if nil != err {
			return nil, errors.Trace(err)
		}

		pack[dir] = &parse.Package{Func: []*parse.Function{}}

		pack[dir].SetAllowedArgument(primitive...)
		pack[dir].SetAllowedReturn(primitive...)

		fset := token.NewFileSet()
		mode := parser.ParseComments | parser.AllErrors

		for _, file := range pkg.GoFiles {
			filePath := filepath.Join(dir, file)
			fileNode, err := parser.ParseFile(fset, filePath, nil, mode)
			if nil != err {
				return nil, errors.Trace(err)
			}
			ast.Walk(pack[dir], fileNode)
		}
	}

	return pack, nil
}

// fileExists returns whether or not a file exists, and if it exists whether or
// not it is a directory.
func fileExists(path string) (exists, isDir bool) {

	stat, err := os.Stat(path)
	exists = err == nil || !os.IsNotExist(err)
	isDir = exists && stat.IsDir()
	return
}
