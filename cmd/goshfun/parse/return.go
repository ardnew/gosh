package parse

import (
	"go/ast"
	"strings"
)

// Return represents an individual return variable in the list of return
// variables of an individual function definition.
type Return struct {
	Name string
	Ref  []Reference
	Type string
}

// NewReturn creates a new Return by inspecting the parsed AST field.
func NewReturn(field *ast.Field) *Return {

	return (&Return{
		Name: "",
		Ref:  []Reference{},
		Type: "",
	}).Parse(field.Type)
}

// Parse constructs an Return by traversing the AST construction.
func (ret *Return) Parse(expr ast.Expr) *Return {

	switch t := expr.(type) {
	case *ast.Ident:
		ret.Type = t.Name
		return ret // base case; we stop recursion once we reach the type name.

	case *ast.ArrayType:
		ret.Ref = append(ret.Ref, RefArray)
		return ret.Parse(t.Elt)

	case *ast.StarExpr:
		ret.Ref = append(ret.Ref, RefPointer)
		return ret.Parse(t.X)
	}

	// shouldn't reach here unless the Expr doesn't have an identifying type,
	// (which I believe is always a syntax error in Go), or we encountered an
	// unrecognized expression and is not currently supported. in either case,
	// this is interpreted as an error, and we cannot use this function.
	return nil
}

func (ret *Return) String() string {

	var sb strings.Builder
	if ret.Name != "" {
		sb.WriteString(ret.Name)
		sb.WriteRune(' ')
	}
	for _, ref := range ret.Ref {
		sb.WriteString(ref.Symbol())
	}
	sb.WriteString(ret.Type)
	return sb.String()

}
