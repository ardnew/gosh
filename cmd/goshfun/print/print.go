package print

import (
	"fmt"
	"io"
	"strings"

	"github.com/ardnew/gosh/cmd/goshfun/parse"
	"github.com/ardnew/gosh/cmd/goshfun/util"
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

	fmt.Fprintf(p.out, "%s {\n", p.fnProto(fun))

	body := p.fnBody(fun)
	for _, ln := range body {
		fmt.Fprintf(p.out, "\t%s\n", ln)
	}

	fmt.Fprintf(p.out, "}\n\n")
}

func (p *Printer) fnArgsName(fun *parse.Function) (name string) {
	return util.PrivateTitle(fun.Name + "Args")
}

func (p *Printer) fnRetsName(fun *parse.Function) (name string) {
	return util.PrivateTitle(fun.Name + "Rets")
}

func (p *Printer) fnArgs(fun *parse.Function) (args string) { return p.fnArgsName(fun) + " ...string" }
func (p *Printer) fnRets(fun *parse.Function) (rets string) { return "([]string, error)" }
func (p *Printer) fnProto(fun *parse.Function) (rets string) {
	return fmt.Sprintf("func %s(%s) %s", fun.FullName(p.pkgName), p.fnArgs(fun), p.fnRets(fun))
}

func (p *Printer) fnBody(fun *parse.Function) (body []string) {

	al, rl := util.Newliner{}, util.Newliner{}

	pName := p.fnArgsName(fun) // name of variable referring to the actual parameter list
	iName := pName + "Index"   // name of variable indexing the actual parameter list

	// number of formal arguments
	numArgs := len(fun.Arg)

	// verify required number of args provided
	reqArgs := fun.MinArgs()
	if reqArgs > 0 {
		al.Add("") // extra spacing for readability.
		al.Addf("if nil == %s || len(%s) < %d {", pName, pName, reqArgs)
		al.Addf("\treturn nil, fmt.Errorf(\"%s: number of arguments (%%d) less than required (%d)\", len(%s))",
			fun.FullName(p.pkgName), reqArgs, pName)
		al.Add("}")
	}

	if len(fun.Arg) > 0 {
		// index of argument in list of actual parameters. since we have to
		// un-flatten the list of input strings from the shell, this can be
		// arbitrarily large, regardless of the number of parameters the real
		// function expects.
		al.Add("")
		al.Addf("%s := 0", iName) // actual argument list index offset
	}

	argList := util.NewUniquer("_")

	for i, arg := range fun.Arg {

		// unique identifier of the typed input argument that will be parsed from
		// the string arguments provided via shell.
		// second parameter specifies how the argument will appear in the actual
		// parameter list of the real function call.
		aName := argList.AddValue(arg.Name, arg.Expression())

		al.Add("") // extra spacing for readability.

		// generate a parser that will convert one string argument to the base type
		// represented by this argument.
		parser := arg.Parser(aName, pName, iName, i, numArgs, reqArgs)
		if nil != parser && len(parser) > 0 {
			// copy each line of the parser to our output.
			for _, l := range parser {
				al.Add(l)
			}
		}
	}

	// number of formal return values
	numRets := len(fun.Ret)

	qName := p.fnRetsName(fun) // name of variable referring to the actual parameter list

	// declare the list that will hold all of our returned output strings
	rl.Addf("%s := []string{}", qName)

	retList := util.NewUniquer("_")

	for i, ret := range fun.Ret {

		rName := retList.Add(fmt.Sprintf("%s%d", qName, i))

		rl.Add("") // extra spacing for readability.

		formatter := ret.Formatter(rName, qName, i, numRets, parse.DefaultFormat)
		if nil != formatter && len(formatter) > 0 {
			// copy each line of the formatter to our output.
			for _, l := range formatter {
				rl.Add(l)
			}
		}
	}

	al.Add("") // extra spacing for readability.

	asgn := ""
	if numRets > 0 {
		asgn = retList.Join(", ") + " := "
	}

	// call our real function!
	al.Add("// ==-==-==-==-==-==-==-==-==-==-==-==")
	al.Addf("%s%s(%s)", asgn, fun.ImportedName(p.pkgName), argList.JoinValues(", "))
	al.Add("// ==-==-==-==-==-==-==-==-==-==-==-==")

	al.Add("") // extra spacing for readability.

	for _, l := range rl {
		al.Add(l)
	}

	al.Add("") // extra spacing for readability.

	al.Add("// ==-==-==-==-==-==-==-==-==-==-==-==")
	al.Addf("return %s, nil", qName)
	al.Add("// ==-==-==-==-==-==-==-==-==-==-==-==")

	return al
}
