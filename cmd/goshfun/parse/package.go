package parse

import (
	"go/ast"
)

// Package represents the list of function signatures exported from a given Go
// package.
type Package struct {
	Func  []*Function
	argOK map[string]bool // base types supported
	retOK map[string]bool //
}

// SetAllowedArgument defines the base type of arguments we want to keep. If an
// argument type identifier encountered does not exist in this list, then the
// entire corresponding function is ignored.
func (pkg *Package) SetAllowedArgument(arg ...string) {
	ok := map[string]bool{}
	for _, t := range arg {
		ok[t] = true
	}
	pkg.argOK = ok
}

// SetAllowedReturn defines the base type of returns we want to keep. If a
// return type identifier encountered does not exist in this list, then the
// entire corresponding function is ignored.
func (pkg *Package) SetAllowedReturn(ret ...string) {
	ok := map[string]bool{}
	for _, t := range ret {
		ok[t] = true
	}
	pkg.retOK = ok
}

func (pkg *Package) allowed(fun *Function) bool {

	for _, arg := range fun.Arg {
		if _, ok := pkg.argOK[arg.Type]; !ok {
			return false
		}
	}
	for _, ret := range fun.Ret {
		if _, ok := pkg.retOK[ret.Type]; !ok {
			return false
		}
	}
	return true
}

// Visit will traverse a given Go package AST and construct a list of function
// signatures uniquely describing all of its available (exported) functions.
func (pkg *Package) Visit(n ast.Node) ast.Visitor {

	if nil == n {
		return nil
	}

	switch o := n.(type) {
	case *ast.FuncDecl:
		if o.Name.IsExported() {
			var fun *Function
			if fun.keep(o) {
				if f := fun.Parse(o); nil != f && pkg.allowed(f) {
					pkg.Func = append(pkg.Func, f)
				}
			}
		}
	}
	return pkg
}
