package print

import (
	"fmt"
	"io"
	"strings"

	"github.com/ardnew/gosh/cmd/goshfun/parse"
	// "github.com/juju/errors"
)

// Printer represents a Go source code generator for translating command-line
// commands into Go library calls.
type Printer struct {
	out     io.Writer
	srcPath string
	pkgName string
}

// NewPrinter creates a new Printer for emitting Go source code from parsed
// package functions.
func NewPrinter(w io.Writer, src, pkg string) *Printer {
	return &Printer{
		out:     w,
		srcPath: src,
		pkgName: strings.TrimPrefix(pkg, src)[1:],
	}
}

// Print prints Go source code that can invoke the functions defined in a given
// parsed package.
func (p *Printer) Print(pkg *parse.Package) {

	for _, fun := range pkg.Func {
		p.PrintFunction(fun)
	}
}

// PrintFunction prints Go source code of an individual function.
func (p *Printer) PrintFunction(fun *parse.Function) {

	// fun.Prototype(false, p.pkgName)
	fmt.Fprintf(p.out, "%s {\n", p.fnProto(fun))

	body := p.fnBody(fun)
	for _, ln := range body {
		fmt.Fprintf(p.out, "\t%s\n", ln)
	}

	fmt.Fprintf(p.out, "}\n\n")
}

func (p *Printer) fnArgs(fun *parse.Function) (args string) { return "in string" }
func (p *Printer) fnRets(fun *parse.Function) (rets string) { return "([]string, error)" }
func (p *Printer) fnProto(fun *parse.Function) (rets string) {
	return fmt.Sprintf("func %s(%s) %s", fun.FullName(p.pkgName), p.fnArgs(fun), p.fnRets(fun))
}

// Newliner represents a string list that is aggregated as a sequence of Go
// source code lines
type Newliner []string

func (nl *Newliner) add(ln string) *Newliner {
	*nl = append(*nl, ln)
	return nl
}

func (nl *Newliner) addf(fm string, ar ...interface{}) *Newliner {

	return nl.add(fmt.Sprintf(fm, ar...))
}

func (p *Printer) fnBody(fun *parse.Function) (body []string) {

	ln := Newliner{}

	// ensure each arg has a unique name
	argSeen := map[string]bool{}
	argName := make([]string, len(fun.Arg))
	for i, arg := range fun.Arg {
		name := arg.Name
		for {
			if _, seen := argSeen[name]; !seen {
				argSeen[name] = true
				break
			} else {
				name = name + "_"
			}
		}
		argName[i] = name
		ln.addf("var %s %s", name, arg.Declaration())
	}

	// verify required number of args provided
	if req := fun.MinArgs(); req > 0 {
		ln.addf("if nil == in || len(in) < %d {", req)
		ln.addf("\treturn nil, fmt.Errorf(\"%s: number of arguments (%%d) less than required (%d)\", len(in))",
			fun.FullName(p.pkgName), req)
		ln.add("}")
	}

	// convert each arg provided from string to its required type

	return ln
}
