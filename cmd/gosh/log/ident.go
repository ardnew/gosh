package log

import (
	"regexp"
	"strings"

	"github.com/juju/errors"
)

// Ident represents one of the enumerated log handler's output modes.
type Ident int

// constants enumerated values for type Ident.
const (
	LogNull Ident = iota
	LogStandard
	LogASCII
	LogJSON
	// -- indices --
	LogCountIdent
	LogFirstIdent   = LogNull
	LogDefaultIdent = LogNull
)

// ParseIdent tries to match the user's given input to an Ident.
func ParseIdent(str string) (Ident, bool) {
	isMatch := func(p string, s string) bool {
		ok, err := regexp.MatchString(`^`+p+`$`, s)
		if err != nil {
			// an error means malformed regexp pattern ~~ "should never reach here"
			panic(errors.Trace(err))
		}
		return ok
	}
	str = strings.ToLower(strings.TrimSpace(str))
	if isMatch(`((/?dev/?)?null|no(ne)?)`, str) {
		return LogNull, true
	} else if isMatch(`(ascii|(plain-?)?te?xt|plain(-?te?xt)?)`, str) {
		return LogASCII, true
	} else if isMatch(`(js(on)?|jq)`, str) {
		return LogJSON, true
	} else if isMatch(`(standard|default|graphic.*|ansi|x?term.*|(u?rx)?vt(-?\d+))`, str) {
		return LogStandard, true
	} else {
		return LogNull, false
	}
}

// IdentNames produces a prettified list of quoted identifier strings available
// to the user for selection as log handler.
func IdentNames() []string {
	n := make([]string, LogCountIdent)
	for i := LogFirstIdent; i < LogCountIdent; i++ {
		// n[i] = fmt.Sprintf("%q", i.String())
		n[i] = i.String()
	}
	return n
}

func (id Ident) String() string {
	if id < 0 || id >= LogCountIdent {
		id = LogDefaultIdent
	}
	return [...]string{"null", "standard", "ascii", "json"}[id]
}
