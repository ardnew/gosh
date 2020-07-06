package config

import (
	"regexp"
	"strings"
)

// ArgExpansion defines the simple single-pass expansion rules performed on the
// args elements defined in the YAML configuration file.
type ArgExpansion struct {
	matcher *regexp.Regexp
	rule    map[string]string
}

// NewArgExpansion constructs a new expansion ruleset with given expansion
// values and compiles the internal key matcher.
func NewArgExpansion(initFile string) *ArgExpansion {
	ae := ArgExpansion{
		rule: map[string]string{
			`__GOSH_INIT__`: initFile,
		},
	}
	ae.matcher = ae.Compile()
	return &ae
}

// Compile builds a regexp pattern that matches a key in the ruleset by simply
// using a group-logical-OR of each key escaped via regexp.QuoteMeta.
func (ae *ArgExpansion) Compile() *regexp.Regexp {
	key := []string{}
	for k := range ae.rule {
		key = append(key, regexp.QuoteMeta(k))
	}
	return regexp.MustCompile(strings.Join(key, "|"))
}

// Expand performs a single-pass literal string substitution according to the
// rule map. If the given arg matches exactly a rule key, then the rule value is
// returned, otherwise the original arg is returned.
func (ae *ArgExpansion) Expand(arg string) string {
	// test if arg matches the RE before stepping through and comparing strings to
	// determine which one to expand.
	if ae.matcher.MatchString(arg) {
		for token, replace := range ae.rule {
			if arg == token {
				return replace
			}
		}
	}
	return arg
}

// ExpandArgs calls Expand on each element in args.
func (ae *ArgExpansion) ExpandArgs(args ...string) []string {
	for i, arg := range args {
		args[i] = ae.Expand(arg)
	}
	return args
}
