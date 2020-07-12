package print

import (
	"fmt"
	"io"
	"sort"
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
}

// NewPrinter creates a new Printer for emitting Go source code from parsed
// package functions.
func NewPrinter(w io.Writer, src string) *Printer {
	return &Printer{
		out:     w,
		srcPath: src,
	}
}

// Println prints the given lines (with newline appended) to the receiver p's
// io.Writer.
func (p *Printer) Println(str ...string) {
	for _, s := range str {
		fmt.Fprintf(p.out, "%s\n", s)
	}
}

func (p *Printer) maskPkgPath(pkgPath string) (name string) {

	return string([]rune(strings.TrimPrefix(pkgPath, p.srcPath))[1:])
}

// PrintHeader prints Go source code containing the main package's imports, type
// definitions, and variable declarations.
func (p *Printer) PrintHeader(pkgs map[string]*parse.Package) {

	p.Println("package main")

	p.Println("")

	// import ( ... )
	for _, ln := range p.headImports(pkgs) {
		fmt.Fprintf(p.out, "%s\n", ln)
	}

	p.Println("")

	// type ( ... )
	for _, ln := range p.headTypes() {
		fmt.Fprintf(p.out, "%s\n", ln)
	}

	p.Println("")

	// var ( ... )
	for _, ln := range p.headVars(pkgs) {
		fmt.Fprintf(p.out, "%s\n", ln)
	}

	p.Println("")
}

// headImports prints Go source code importing the packages required to support
// the requested function exports.
func (p *Printer) headImports(pkgs map[string]*parse.Package) (imps []string) {

	var imports = map[string]bool{
		"flag":          true,
		"fmt":           true,
		"os":            true,
		"path/filepath": true,
		"strconv":       true,
		"strings":       true,
		"unicode/utf8":  true,
	}

	ln := util.Newliner{}

	ln.Addf("import (")

	pkgName := []string{}

	for name := range imports {
		pkgName = append(pkgName, name)
	}

	for path := range pkgs {
		name := p.maskPkgPath(path)
		if _, seen := imports[name]; !seen {
			pkgName = append(pkgName, name)
		}
	}

	// sort imported package names alphabetically
	sort.Slice(pkgName,
		func(i, j int) bool {
			return strings.Compare(pkgName[i], pkgName[j]) < 0
		})

	for _, name := range pkgName {
		ln.Addf("\t%q", name)
	}

	ln.Addf(")")

	return ln
}

// headTypes prints Go source code defining all of the local type definitions
// needed to encapsulate calls to the exported functions.
func (p *Printer) headTypes() (typs []string) {

	ln := util.Newliner{}

	ln.Add("type (")

	ln.Add("\tfunctionCall func(...string) ([]string, error)")

	ln.Add("\tfunctionProperty struct {")
	ln.Add("\t\tname string")
	ln.Add("\t\targs string")
	ln.Add("\t\trets string")
	ln.Add("\t\tcfun functionCall")
	ln.Add("\t}")

	ln.Add("\tfunctionTable map[string]*functionProperty")

	ln.Add(")")

	return ln
}

// headVars prints Go source code declaring and/or defining global variables
// used by the main package.
func (p *Printer) headVars(pkgs map[string]*parse.Package) (vars []string) {

	ln := util.Newliner{}

	if len(pkgs) > 0 {

		ln.Add("var (")

		ln.Addf("\t%s string", "realName")
		ln.Addf("\t%s string", "invoName")
		ln.Addf("\t%s string", "flagName")
		ln.Addf("\t%s bool", "flagNull")

		// declare the FunctionList lookup table, associating a string name with a
		// functionProperty.
		ln.Add("\tfunctions = map[string]*functionTable {")

		for _, s := range p.headVarsPkg(pkgs) {
			ln.Addf("\t\t%s", s)
		}

		ln.Add("\t}")

		ln.Add(")")
	}

	return ln
}

func (p *Printer) headVarsPkg(pkgs map[string]*parse.Package) (vars []string) {

	ln := util.Newliner{}

	// build each of the functionProperty variable declarations for all exported
	// functions in all of the requested paths.
	for path, pkg := range pkgs {
		pkgName := p.maskPkgPath(path)
		ln.Addf("%q: &functionTable{", pkgName)
		for _, fun := range pkg.Func {
			_, args, rets := fun.Elements(true, pkgName)
			ln.Addf("\t%q: &functionProperty{", fun.Name)
			ln.Addf("\t\tname: %q,", fun.ImportedName(pkgName))
			ln.Addf("\t\targs: %q,", strings.Join(args, " "))
			ln.Addf("\t\trets: %q,", strings.Join(rets, " "))
			ln.Addf("\t\tcfun: %s,", fun.FullName(pkgName))
			ln.Addf("\t},")
		}
		ln.Add("},")
	}

	return ln
}

// PrintBody prints Go source code containing all functions defined in the
// main package.
func (p *Printer) PrintBody() {

	for _, ln := range p.bodyMain() {
		fmt.Fprintf(p.out, "%s\n", ln)
	}

	for _, ln := range p.bodyUsage() {
		fmt.Fprintf(p.out, "%s\n", ln)
	}

	for _, ln := range p.bodyResolve() {
		fmt.Fprintf(p.out, "%s\n", ln)
	}
}

// bodyMain prints Go source code containing the main function.
func (p *Printer) bodyMain() (main []string) {

	ln := util.Newliner{}

	ln.Add(`
func main() {

	exe, exeErr := os.Executable()
	if nil != exeErr {
		panic(exeErr)
	}
	realName = filepath.Base(exe)
	invoName = filepath.Base(os.Args[0])

	if invoName == realName {
		flag.StringVar(&flagName, "f", "", "invoke function named ` + "`func`" + `.")
	}
	flag.BoolVar(&flagNull, "0", false, "delimit ouput parameters with a null byte ('\\0') instead of a newline ('\\n').")

	flag.CommandLine.Usage = func() { printUsage(invoName) }
	flag.Parse()

	funcName, funcArgs := invoName, os.Args[1:]
	if "" != flagName {
		funcName, funcArgs = flagName, flag.Args()
	}

	_, _, prop, ok := resolve(funcName)
	if !ok {
		printUsage(realName)
	} else {
		if funcRets, err := prop.cfun(funcArgs...); nil != err {
			fmt.Fprintf(os.Stderr, "%s\n", err)
		} else {
			if nil != funcRets && len(funcRets) > 0 {
				for _, out := range funcRets {
					var output strings.Builder
					output.WriteString(out)
					if flagNull {
						output.WriteByte(0)
					} else {
						output.WriteRune('\n')
					}
					fmt.Print(output.String())
				}
			}
		}
	}
}`)

	return ln
}

func (p *Printer) bodyUsage() (usage []string) {

	ln := util.Newliner{}

	ln.Add(`
func printUsage(name string) {

	pkg, fun, prop, ok := resolve(name)

	if name == realName || !ok {
		fmt.Printf("Usage of %s:\n", name)
		flag.PrintDefaults()
		fmt.Printf("\nThe following library functions are supported:\n")
		for pkg, table := range functions {
			fmt.Printf("\tpackage %s:\n", pkg)
			for fn, pr := range *table {
				fmt.Printf("\t\t%s", fn)
				if "" != pr.args || "" != pr.rets {
					fmt.Printf(":")
					if "" != pr.args {
						fmt.Printf(" %s", pr.args)
					}
					if "" != pr.rets {
						fmt.Printf(" -> %s", pr.rets)
					}
				}
				fmt.Printf("\n")
			}
		}
	} else {
		fmt.Printf("Usage of (%q) %s:\n", pkg, fun)
		fmt.Printf("\t%s %s\n", name, prop.args)
		if prop.rets != "" {
			fmt.Printf("\t\treturns: %s\n", prop.rets)
		}
	}
}`)

	return ln
}

func (p *Printer) bodyResolve() (rslv []string) {

	ln := util.Newliner{}

	ln.Add(`
func resolve(name string) (pkg, fun string, prop *functionProperty, ok bool) {

	if name != "" {

		var ip, in string
		if spl := strings.Split(name, "."); len(spl) > 1 {
			ip = filepath.Join(spl[:len(spl)-1]...)
			in = spl[len(spl)-1]
		} else {
			in = name
		}

		if ip != "" {
			// check if only the import package name was provided
			//   e.g. "filepath" in "path/filepath"
			_, iip := filepath.Split(strings.ReplaceAll(ip, ".", string(filepath.Separator)))
			for pkg := range functions {
				_, pip := filepath.Split(pkg)
				if iip == pip {
					ip = pkg
					break
				}
			}
			// use the package that was provided, don't check all for a matching func.
			dip := strings.ReplaceAll(ip, ".", string(filepath.Separator))
			if lt, pok := functions[dip]; pok {
				if pr, tok := (*lt)[in]; tok {
					return ip, in, pr, true
				}
			}
		} else {
			// no package provided, check all for a matching func.
			for pk, lt := range functions {
				if pr, tok := (*lt)[in]; tok {
					return pk, in, pr, true
				}
			}
		}
	}
	return "", "", nil, false
}`)

	return ln
}

// PrintPackage prints Go source code containing all functions defined in the
// main package.
func (p *Printer) PrintPackage(verbose bool, pkgPath string, pkg *parse.Package) {

	pkgName := p.maskPkgPath(pkgPath)

	for _, fun := range pkg.Func {
		fmt.Fprintf(p.out, "\n")
		for _, ln := range p.pkgFunc(pkgName, fun) {
			fmt.Fprintf(p.out, "%s\n", ln)
		}
		if verbose {
			fmt.Printf("\t%s", fun.ImportedName(pkgName))
			_, args, rets := fun.Elements(true, pkgName)
			haveArgs := nil != args && len(args) > 0
			haveRets := nil != rets && len(rets) > 0
			if haveArgs || haveRets {
				fmt.Printf(":")
				if haveArgs {
					fmt.Printf(" %s", strings.Join(args, " "))
				}
				if haveRets {
					fmt.Printf(" -> %s", strings.Join(rets, " "))
				}
				fmt.Println("")
			}
		}
	}
}

// pkgFunc prints Go source code of an individual function.
func (p *Printer) pkgFunc(pkgName string, fun *parse.Function) (body []string) {

	nl := util.Newliner{}

	nl.Addf("%s {", p.pkgFuncProto(pkgName, fun))

	bod := p.pkgFuncBody(pkgName, fun)
	for _, ln := range bod {
		nl.Addf("\t%s", ln)
	}
	nl.Addf("}")

	return nl
}

func (p *Printer) pkgFuncBody(pkgName string, fun *parse.Function) (body []string) {

	al, rl := util.Newliner{}, util.Newliner{}

	pName := p.pkgFuncArgsName(fun) // name of variable referring to the actual parameter list
	iName := pName + "Index"        // name of variable indexing the actual parameter list

	// number of formal arguments
	numArgs := len(fun.Arg)

	// verify required number of args provided
	reqArgs := fun.MinArgs()
	if reqArgs > 0 {
		al.Add("") // extra spacing for readability.
		al.Addf("if nil == %s || len(%s) < %d {", pName, pName, reqArgs)
		al.Addf("\treturn nil, fmt.Errorf(\"%s: number of arguments (%%d) less than required (%d)\", len(%s))",
			fun.ImportedName(pkgName), reqArgs, pName)
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

	qName := p.pkgFuncRetsName(fun) // name of variable referring to the actual parameter list

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
	al.Addf("%s%s(%s)", asgn, fun.ImportedName(pkgName), argList.JoinValues(", "))
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

func (p *Printer) pkgFuncArgs(fun *parse.Function) (args string) {
	return p.pkgFuncArgsName(fun) + " ...string"
}

func (p *Printer) pkgFuncArgsName(fun *parse.Function) (name string) {
	return util.PrivateTitle(fun.Name + "Args")
}

func (p *Printer) pkgFuncRets(fun *parse.Function) (rets string) {
	return "([]string, error)"
}

func (p *Printer) pkgFuncRetsName(fun *parse.Function) (name string) {
	return util.PrivateTitle(fun.Name + "Rets")
}

func (p *Printer) pkgFuncProto(pkgName string, fun *parse.Function) (rets string) {
	return fmt.Sprintf("func %s(%s) %s", fun.FullName(pkgName), p.pkgFuncArgs(fun), p.pkgFuncRets(fun))
}
