package parse

import (
	"go/ast"
	"strings"

	"github.com/ardnew/gosh/cmd/goshfun/util"
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

	return ret.ProtoSh()
}

// IsListRef returns whether or not the reference at index ri is one of the list
// types (array or ellipses).
func (ret *Return) IsListRef(ri int) bool {

	return nil != ret && ri < len(ret.Ref) &&
		(RefArray == ret.Ref[ri] || RefEllipses == ret.Ref[ri])
}

// ProtoGo returns the signature used for this Return value for the Go
// interface.
func (ret *Return) ProtoGo() string {

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

// ProtoSh returns the signature used for this Return value for the shell
// interface.
func (ret *Return) ProtoSh() string {

	var sb strings.Builder
	for _, ref := range ret.Ref {
		switch ref {
		case RefArray, RefEllipses:
			sb.WriteString(RefEllipses.Symbol())
			break
		}
	}
	if ret.Name != "" {
		sb.WriteString(ret.Name)
	} else {
		sb.WriteString(ret.Type)
	}
	return sb.String()

}

// Prototype returns the signature used for this Return value for either the
// shell interface or the Go interface.
func (ret *Return) Prototype(sh bool) string {
	if sh {
		return ret.ProtoSh()
	}
	return ret.ProtoGo()
}

// Declaration returns a representation of the type of this return variable that
// can be attached to a local variable identifier.
func (ret *Return) Declaration() string {

	var a string
	var hasList bool
	for _, ref := range ret.Ref {
		switch ref {
		case RefArray, RefEllipses:
			if hasList {
				// currently do not support list indirection
				break
			}
			a = a + RefArray.Symbol()
			hasList = true
		case RefPointer:
			a = a + ref.Symbol()
		}
	}
	return a + ret.Type
}

// FormatOptions stores the various formatting options used to format a Return
// value as a string.
type FormatOptions struct {
	IntegerBase      int
	FloatFormat      byte
	FloatPrecision   int
	ComplexFormat    byte
	ComplexPrecision int
}

// DefaultFormat contains the default formatting options for a Return value
// formatted as a string.
var DefaultFormat = FormatOptions{
	IntegerBase:      10,
	FloatFormat:      'g',
	FloatPrecision:   -1, // special value, "min digits required for exact rep"
	ComplexFormat:    'g',
	ComplexPrecision: -1, // special value, same as FloatPrecision
}

// Formatter returns a slice of Go source code lines defining an anonymous
// function that will convert a variable whose type is identified by the
// receiver ret's Type into a string.
func (ret *Return) Formatter(rName, qName string, retPos, numRets int, format FormatOptions) []string {

	ln, fn := util.Newliner{}, util.Newliner{}

	fName := "format" + strings.Title(rName)

	iWidth := util.NumDigits(numRets)

	ln.Addf("// -------------------------------------")
	ln.Addf("//  %*d | %s -> %s", iWidth, retPos, rName, ret.Declaration())
	ln.Addf("// -------------------------------------")
	ln.Addf("%s := func(input %s) string {", fName, ret.Type)

	switch ret.Type {
	case "rune":
		fn.Add("return string(input)")
	case "string":
		fn.Add("return input")
	case "error":
		fn.Add("if nil != input {")
		fn.Add("	return input.Error()")
		fn.Add("}")
		fn.Add("return \"\"")
	case "bool":
		fn.Add("return strconv.FormatBool(input)")
	case "byte":
		fn.Addf("return strconv.FormatUint(uint64(input), %d)", format.IntegerBase)
	case "int":
		fn.Addf("return strconv.FormatInt(int64(input), %d)", format.IntegerBase)
	case "int8":
		fn.Addf("return strconv.FormatInt(int64(input), %d)", format.IntegerBase)
	case "int16":
		fn.Addf("return strconv.FormatInt(int64(input), %d)", format.IntegerBase)
	case "int32":
		fn.Addf("return strconv.FormatInt(int64(input), %d)", format.IntegerBase)
	case "int64":
		fn.Addf("return strconv.FormatInt(int64(input), %d)", format.IntegerBase)
	case "uint":
		fn.Addf("return strconv.FormatUint(uint64(input), %d)", format.IntegerBase)
	case "uint8":
		fn.Addf("return strconv.FormatUint(uint64(input), %d)", format.IntegerBase)
	case "uint16":
		fn.Addf("return strconv.FormatUint(uint64(input), %d)", format.IntegerBase)
	case "uint32":
		fn.Addf("return strconv.FormatUint(uint64(input), %d)", format.IntegerBase)
	case "uint64":
		fn.Addf("return strconv.FormatUint(uint64(input), %d)", format.IntegerBase)
	case "uintptr":
		fn.Addf("return strconv.FormatUint(uint64(input), %d)", format.IntegerBase)
	case "float32":
		fn.Addf("return strconv.FormatFloat(float64(input), %d, %d, 32)", format.FloatFormat, format.FloatPrecision)
	case "float64":
		fn.Addf("return strconv.FormatFloat(float64(input), %d, %d, 64)", format.FloatFormat, format.FloatPrecision)
	case "complex64":
		fn.Addf("return strconv.FormatComplex(complex128(input), %d, %d, 64)", format.ComplexFormat, format.ComplexPrecision)
	case "complex128":
		fn.Addf("return strconv.FormatComplex(complex128(input), %d, %d, 128)", format.ComplexFormat, format.ComplexPrecision)
	default:
		fn.Add("return nil")
	}

	for _, s := range fn {
		ln.Addf("\t%s", s)
	}

	ln.Add("}")

	if ret.IsListRef(0) {
		ln.Addf("for _, r := range %s {", rName)
		ln.Addf("\t%s = append(%s, %s(r))", qName, qName, fName)
		ln.Add("}")
	} else {
		ln.Addf("%s = append(%s, %s(%s))", qName, qName, fName, rName)
	}

	return ln
}
