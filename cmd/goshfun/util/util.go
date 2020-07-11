package util

import (
	"fmt"
	"math"
	"strings"
	"unicode"
)

// Newliner represents a string list that is aggregated as a sequence of Go
// source code lines
type Newliner []string

// Add appends a new line to receiver.
func (nl *Newliner) Add(ln string) *Newliner {
	*nl = append(*nl, ln)
	return nl
}

// Addf appends a new line with given printf-style format and args to receiver.
func (nl *Newliner) Addf(fm string, ar ...interface{}) *Newliner {
	return nl.Add(fmt.Sprintf(fm, ar...))
}

// NumDigits returns the number of decimal digits in uint n.
func NumDigits(n int) int {
	if n >= 0 {
		return int(math.Floor(math.Log10(float64(n)))) + 1
	}
	return -1 // return invalid value for invalid input
}

// PrivateTitle is like strings.Title(), except the first Unicode letter in s is
// mapped to its Unicode lower case.
func PrivateTitle(s string) string {
	p := []rune(strings.Title(s))
	p[0] = unicode.ToLower(p[0])
	return string(p)
}
