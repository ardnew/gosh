package parse

import (
	"fmt"
	"go/ast"
	"go/token"
	"path/filepath"
	"strings"
)

// Function represents the signature or definition of an individual function.
type Function struct {
	Name string
	Arg  []*Argument
	Ret  []*Return
}

// keep quickly inspects the outer-most attributes of an AST function node to
// determine if we can use the function.
func (fun *Function) keep(decl *ast.FuncDecl) bool {

	// currently functions-only; no support for methods (i.e., has a receiver)
	return (decl.Type.Func != token.NoPos) && (decl.Recv == nil)
}

// Parse constructs an individual function signature using a node in the AST
// parsed from a given Go package. Returns affirmation function is supported,
// i.e., has a signature we currently support.
func (fun *Function) Parse(decl *ast.FuncDecl) *Function {

	fun = &Function{
		Name: decl.Name.Name,
		Arg:  []*Argument{},
		Ret:  []*Return{},
	}

	if nil != decl.Type.Params {
		for _, f := range decl.Type.Params.List {
			arg := NewArgument(f)
			if nil == arg {
				// encountered an unsupported expression, discard entire function
				return nil
			}
			if nil == f.Names || len(f.Names) == 0 {
				fun.Arg = append(fun.Arg, arg)
			} else {
				// duplicate for each field name (e.g., "a, b int" -> "a int, b int")
				for _, name := range f.Names {
					var a Argument = *arg
					a.Name = name.Name
					fun.Arg = append(fun.Arg, &a)
				}
			}
		}
	}

	if nil != decl.Type.Results {
		for _, f := range decl.Type.Results.List {
			ret := NewReturn(f)
			if nil == ret {
				// encountered an unsupported expression, discard entire function
				return nil
			}
			if nil == f.Names || len(f.Names) == 0 {
				fun.Ret = append(fun.Ret, ret)
			} else {
				// duplicate for each field name (e.g., "a, b int" -> "a int, b int")
				for _, name := range f.Names {
					var r Return = *ret
					r.Name = name.Name
					fun.Ret = append(fun.Ret, &r)
				}
			}
		}
	}

	return fun
}

// ProtoGo returns the signature of this function for the Go interface.
func (fun *Function) ProtoGo(pkg string) string {

	var sb strings.Builder
	name, args, rets := fun.elements(false, pkg)
	sb.WriteString(fmt.Sprintf("func %s(%s)", name, strings.Join(args, ", ")))
	if len(rets) > 0 {
		r := strings.Join(rets, ", ")
		if len(rets) > 1 {
			r = "(" + r + ")"
		}
		sb.WriteRune(' ')
		sb.WriteString(r)
	}
	return sb.String()
}

// ProtoSh returns the signature of this function for the shell interface.
func (fun *Function) ProtoSh(pkg string) string {

	var sb strings.Builder
	name, args, rets := fun.elements(true, pkg)
	sb.WriteString(name + ":")
	if len(args) > 0 {
		sb.WriteString(" " + strings.Join(args, " "))
	}
	if len(rets) > 0 {
		sb.WriteString(fmt.Sprintf(" -> %s", strings.Join(rets, " ")))
	}
	return sb.String()
}

// Prototype returns the signature of this function for either the Go or the
// shell interface.
func (fun *Function) Prototype(sh bool, pkg string) string {

	if sh {
		return fun.ProtoSh(pkg)
	}
	return fun.ProtoGo(pkg)
}

// FullName returns the fully-qualified name of the receiver fun, escaped for
// use as either Go function or shell command.
func (fun *Function) FullName(pkg string) string {

	var pf string
	if pkg = strings.TrimSpace(pkg); "" != pkg {
		pf = strings.ReplaceAll(pkg, "/", "ノ") + "ㆍ"
	}
	return pf + fun.Name
}

// ImportedName returns the import-qualified name of the receiver fun.
func (fun *Function) ImportedName(pkg string) string {

	var pf string
	if pkg = strings.TrimSpace(pkg); "" != pkg {
		_, pf = filepath.Split(pkg)
		pf += "."
	}
	return pf + fun.Name
}

// MinArgs returns the minimum number of arguments required to invoke this
// function.
func (fun *Function) MinArgs() int {

	min := len(fun.Arg)
	if min > 0 {
		for _, arg := range fun.Arg {
			if len(arg.Ref) > 0 && (RefEllipses == arg.Ref[0] || RefArray == arg.Ref[0]) {
				min--
			}
		}
	}
	return min
}

func (fun *Function) elements(sh bool, pkg string) (name string, args, rets []string) {

	name = fun.FullName(pkg)

	args = make([]string, len(fun.Arg))
	for i, a := range fun.Arg {
		args[i] = fmt.Sprintf("%s", a.Prototype(sh))
	}

	rets = make([]string, len(fun.Ret))
	for i, r := range fun.Ret {
		rets[i] = fmt.Sprintf("%s", r.Prototype(sh))
	}

	return name, args, rets
}
