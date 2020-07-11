package parse

import (
	"go/ast"
	"strings"

	"github.com/ardnew/gosh/cmd/goshfun/util"
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

	return arg.ProtoSh()
}

// IsListRef returns whether or not the reference at index ri is one of the list
// types (array or ellipses).
func (arg *Argument) IsListRef(ri int) bool {

	return nil != arg && ri < len(arg.Ref) &&
		(RefArray == arg.Ref[ri] || RefEllipses == arg.Ref[ri])
}

// ProtoGo returns the signature used for this Argument value for the Go
// interface.
func (arg *Argument) ProtoGo() string {

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

// ProtoSh returns the signature used for this Argument value for the shell
// interface.
func (arg *Argument) ProtoSh() string {

	var sb strings.Builder
	for _, ref := range arg.Ref {
		switch ref {
		case RefArray, RefEllipses:
			sb.WriteString(RefEllipses.Symbol())
			break
		}
	}
	if arg.Name != "" {
		sb.WriteString(arg.Name)
	} else {
		sb.WriteString(arg.Type)
	}
	return sb.String()

}

// Prototype returns the signature used for this Argument value for either the
// shell interface or the Go interface.
func (arg *Argument) Prototype(sh bool) string {
	if sh {
		return arg.ProtoSh()
	}
	return arg.ProtoGo()
}

// Declaration returns a representation of the type of this argument that can be
// attached to a local variable identifier.
func (arg *Argument) Declaration() string {

	var a string
	var hasList bool
	for _, ref := range arg.Ref {
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
	return a + arg.Type
}

// Expression returns a string representation of the receiver arg suitable for
// passing on as argument in a function call.
func (arg *Argument) Expression() string {

	s := arg.Name
	// we only support a single level of indirection or enumeration...
	if len(arg.Ref) > 0 && RefEllipses == arg.Ref[0] {
		s += RefEllipses.Symbol()
	}
	return s
}

// Parser returns a slice of Go source code lines defining an anonymous function
// that will parse a string into a variable whose type is identified by the
// receiver arg's Type.
func (arg *Argument) Parser(aName, pName, iName string, argPos, numArgs, reqArgs int) []string {

	ln, fn := util.Newliner{}, util.Newliner{}
	eName := aName + "Err"
	fName := "parse" + strings.Title(aName)

	iWidth := util.NumDigits(numArgs)

	ln.Addf("// -------------------------------------")
	ln.Addf("//  %*d | %s -> %s", iWidth, argPos, aName, arg.Declaration())
	ln.Addf("// -------------------------------------")
	ln.Addf("var %s %s", aName, arg.Declaration())
	ln.Addf("var %s error", eName)
	ln.Addf("%s := func(input string) (%s, error) {", fName, arg.Type)

	switch arg.Type {

	case "rune":
		fn.Add("if len(input) > 0 {")
		fn.Add("\tr, _ := utf8.DecodeRuneInString(input)")
		fn.Add("\tif utf8.RuneError != r {")
		fn.Add("\t\treturn r, nil")
		fn.Add("\t}")
		fn.Add("\treturn utf8.RuneError, fmt.Errorf(\"invalid UTF-8 encoding: %s\", input)")
		fn.Add("}")
		fn.Add("return utf8.RuneError, fmt.Errorf(\"empty string (0 bytes)\")")

	case "string":
		// no conversion necessary
		fn.Add("return input, nil")

	case "error":
		fn.Add("return fmt.Errorf(\"%s\", input), nil")

	case "bool":
		fn.Add("b, err := strconv.ParseBool(input)")
		fn.Add("if nil != err {")
		fn.Add("\treturn false, err")
		fn.Add("}")
		fn.Add("return b, nil")

	case "byte":
		fn.Add("u, err := strconv.ParseUint(input, 0, 8)")
		fn.Add("if nil != err {")
		fn.Add("\treturn 0, err")
		fn.Add("}")
		fn.Add("return byte(u), nil")

	case "int":
		fn.Add("d, err := strconv.ParseInt(input, 0, strconv.IntSize)")
		fn.Add("if nil != err {")
		fn.Add("\treturn 0, err")
		fn.Add("}")
		fn.Add("return int(d), nil")

	case "int8":
		fn.Add("d, err := strconv.ParseInt(input, 0, 8)")
		fn.Add("if nil != err {")
		fn.Add("\treturn 0, err")
		fn.Add("}")
		fn.Add("return int8(d), nil")

	case "int16":
		fn.Add("d, err := strconv.ParseInt(input, 0, 16)")
		fn.Add("if nil != err {")
		fn.Add("\treturn 0, err")
		fn.Add("}")
		fn.Add("return int16(d), nil")

	case "int32":
		fn.Add("d, err := strconv.ParseInt(input, 0, 32)")
		fn.Add("if nil != err {")
		fn.Add("\treturn 0, err")
		fn.Add("}")
		fn.Add("return int32(d), nil")

	case "int64":
		fn.Add("d, err := strconv.ParseInt(input, 0, 64)")
		fn.Add("if nil != err {")
		fn.Add("\treturn 0, err")
		fn.Add("}")
		fn.Add("return int64(d), nil")

	case "uint":
		fn.Add("u, err := strconv.ParseUint(input, 0, strconv.IntSize)")
		fn.Add("if nil != err {")
		fn.Add("\treturn 0, err")
		fn.Add("}")
		fn.Add("return uint(u), nil")

	case "uint8":
		fn.Add("u, err := strconv.ParseUint(input, 0, 8)")
		fn.Add("if nil != err {")
		fn.Add("\treturn 0, err")
		fn.Add("}")
		fn.Add("return uint8(u), nil")

	case "uint16":
		fn.Add("u, err := strconv.ParseUint(input, 0, 16)")
		fn.Add("if nil != err {")
		fn.Add("\treturn 0, err")
		fn.Add("}")
		fn.Add("return uint16(u), nil")

	case "uint32":
		fn.Add("u, err := strconv.ParseUint(input, 0, 32)")
		fn.Add("if nil != err {")
		fn.Add("\treturn 0, err")
		fn.Add("}")
		fn.Add("return uint32(u), nil")

	case "uint64":
		fn.Add("u, err := strconv.ParseUint(input, 0, 64)")
		fn.Add("if nil != err {")
		fn.Add("\treturn 0, err")
		fn.Add("}")
		fn.Add("return uint64(u), nil")

	case "uintptr":
		fn.Add("u, err := strconv.ParseUint(input, 0, strconv.IntSize)")
		fn.Add("if nil != err {")
		fn.Add("\treturn 0, err")
		fn.Add("}")
		fn.Add("return uintptr(u), nil")

	case "float32":
		fn.Add("f, err := strconv.ParseFloat(input, 32)")
		fn.Add("if nil != err {")
		fn.Add("\treturn 0, err")
		fn.Add("}")
		fn.Add("return float32(f), nil")

	case "float64":
		fn.Add("f, err := strconv.ParseFloat(input, 64)")
		fn.Add("if nil != err {")
		fn.Add("\treturn 0, err")
		fn.Add("}")
		fn.Add("return float64(f), nil")

	case "complex64":
		fn.Add("i, err := strconv.ParseComplex(input, 64)")
		fn.Add("if nil != err {")
		fn.Add("\treturn 0, err")
		fn.Add("}")
		fn.Add("return complex64(i), nil")

	case "complex128":
		fn.Add("i, err := strconv.ParseComplex(input, 128)")
		fn.Add("if nil != err {")
		fn.Add("\treturn 0, err")
		fn.Add("}")
		fn.Add("return complex128(i), nil")

	default:
		fn.Add("return nil, nil")
	}

	for _, s := range fn {
		ln.Addf("\t%s", s)
	}

	ln.Add("}")

	if arg.IsListRef(0) {
		ln.Addf("%s = make(%s, len(%s)-%d)", aName, arg.Declaration(), pName, reqArgs)
		ln.Addf("for i := 0; i < len(%s)-%d; i++ {", pName, reqArgs)
		ln.Addf("\t%s[i], %s = %s(%s[%s])", aName, eName, fName, pName, iName)
		ln.Addf("\tif nil != %s {", eName)
		ln.Add("\t\tbreak")
		ln.Add("\t}")
		ln.Addf("\t%s++", iName)
		ln.Add("}")
	} else {
		ln.Addf("%s, %s = %s(%s[%s])", aName, eName, fName, pName, iName)
		ln.Addf("%s++", iName)
	}

	ln.Addf("if nil != %s {", eName)
	ln.Addf("\treturn nil, %s", eName)
	ln.Add("}")

	return ln
}
