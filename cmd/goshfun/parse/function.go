package parse

import (
	"go/ast"
	"go/token"
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
