package util

import "strings"

// Uniquer represents a collection of unique strings.
type Uniquer struct {
	dict   map[string]string
	key    []string // stores the order in which the strings were added
	val    []string //
	suffix string
}

// NewUniquer creates a new collection of unique strings. Duplicate strings will
// be distinguished by having suffix appended to it
func NewUniquer(suffix string) *Uniquer {
	return &Uniquer{
		dict:   map[string]string{},
		key:    []string{},
		val:    []string{},
		suffix: suffix,
	}
}

// Add adds a new string to the collection. If the string already exists, it
// is appended with u.Suffix repeatedly until it is unique. Uses the original
// string value this method was called with as auxiliary value.
// Returns the resulting unique name.
func (u *Uniquer) Add(key string) string {
	return u.AddValue(key, key)
}

// AddValue adds a new string to the collection like Add, but with a specific
// auxiliary value that can be later retrieved with Values or JoinValues.
// Returns the resulting unique name.
func (u *Uniquer) AddValue(key, val string) string {
	seen := true
	for seen {
		if _, seen = u.dict[key]; seen {
			key += u.suffix
		}
	}
	u.dict[key] = val
	u.key = append(u.key, key)
	u.val = append(u.val, val)
	return key
}

// Strings returns the unique strings in u, sorted by the index or order in
// which the string was added.
func (u *Uniquer) Strings() []string {
	return u.key
}

// Values returns the values associated with each unique string in u, sorted by
// the index or order in which the string was added.
func (u *Uniquer) Values() []string {
	return u.val
}

// Join concatenates all of the unique strings in u, separated by string sep,
// and sorted by the index or order in which the string was added.
func (u *Uniquer) Join(sep string) string {
	return strings.Join(u.key, sep)
}

// JoinValues concatenates all of values associated with the unique strings in
// u, separated by string sep, and sorted by the index or order in which the
// string was added.
func (u *Uniquer) JoinValues(sep string) string {
	return strings.Join(u.val, sep)
}
