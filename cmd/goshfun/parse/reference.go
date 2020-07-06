package parse

// Reference represents a reference to a subtype in either the argument list or
// the return list of a function definition.
type Reference int

// Constant values for the enumerated type Reference.
const (
	RefNone Reference = iota
	RefArray
	RefEllipses
	RefPointer
)

// String returns a human-readable description of ref.
func (ref Reference) String() string {
	return [...]string{"none", "array", "ellipses", "pointer"}[ref]
}

// Symbol returns the string used in Go syntax to express ref.
func (ref Reference) Symbol() string {
	return [...]string{"", "[]", "...", "*"}[ref]
}
