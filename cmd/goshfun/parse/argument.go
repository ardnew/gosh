package parse

import (
	"go/ast"
	"strings"
)

// Argument represents an individual argument variable in the list of argument
// variables of an individual function definition.
type Argument struct {
	Name string
	Ref  []Reference
	Type string
}

// NewArgument creates a new Argument by inspecting the parsed AST field.
func NewArgument(field *ast.Field) *Argument {

	return (&Argument{
		Name: "",
		Ref:  []Reference{},
		Type: "",
	}).Parse(field.Type)
}

// Parse constructs an Argument by traversing the AST construction.
func (arg *Argument) Parse(expr ast.Expr) *Argument {

	switch t := expr.(type) {
	case *ast.Ident:
		arg.Type = t.Name
		return arg // base case; we stop recursion once we reach the type name.

	case *ast.ArrayType:
		arg.Ref = append(arg.Ref, RefArray)
		return arg.Parse(t.Elt)

	case *ast.Ellipsis:
		arg.Ref = append(arg.Ref, RefEllipses)
		return arg.Parse(t.Elt)

	case *ast.StarExpr:
		arg.Ref = append(arg.Ref, RefPointer)
		return arg.Parse(t.X)
	}

	// shouldn't reach here unless the Expr doesn't have an identifying type,
	// (which I believe is always a syntax error in Go), or we encountered an
	// unrecognized expression and is not currently supported. in either case,
	// this is interpreted as an error, and we cannot use this function.
	return nil
}

func (arg *Argument) String() string {

	var sb strings.Builder
	if arg.Name != "" {
		sb.WriteString(arg.Name)
		sb.WriteRune(' ')
	}
	for _, ref := range arg.Ref {
		sb.WriteString(ref.Symbol())
	}
	sb.WriteString(arg.Type)
	return sb.String()
}
