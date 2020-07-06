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
		pkgName: strings.ReplaceAll(strings.TrimPrefix(pkg, src)[1:], "/", "."),
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

	name, args, rets := p.prototype(fun)
	fmt.Fprintf(p.out, "func %s(%s) ", name, args)
	if len(rets) > 0 {
		fmt.Fprintf(p.out, "%s {\n", rets)
	} else {
		fmt.Fprintf(p.out, "{\n")
	}

	body := p.body(fun)
	for _, ln := range body {
		fmt.Fprintf(p.out, "\t%s\n", ln)
	}

	fmt.Fprintf(p.out, "}\n\n")
}

func (p *Printer) prototype(fun *parse.Function) (name, args, rets string) {

	name = fmt.Sprintf("%s_%s", strings.ReplaceAll(p.pkgName, ".", "_"), fun.Name)

	arg := make([]string, len(fun.Arg))
	for i, a := range fun.Arg {
		arg[i] = fmt.Sprintf("%s", a.String())
	}
	args = strings.Join(arg, ", ")

	ret := make([]string, len(fun.Ret))
	for i, r := range fun.Ret {
		ret[i] = fmt.Sprintf("%s", r.String())
	}
	rets = strings.Join(ret, ", ")
	if len(ret) > 1 {
		rets = "(" + rets + ")"
	}

	return name, args, rets
}

func (p *Printer) body(fun *parse.Function) (body []string) {
	return []string{"body"}
}
