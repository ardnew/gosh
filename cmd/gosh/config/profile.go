package config

import (
	"fmt"
	"strings"
)

// Profile represents gosh environments to load.
type Profile []string

// String constructs a descriptive representation of a Profile.
func (p *Profile) String() string {

	q := []string{}
	for _, s := range *p {
		q = append(q, fmt.Sprintf("%q", s))
	}
	return fmt.Sprintf("[%s]", strings.Join(q, ", "))
}

// Set implements the flag.Value interface to parse profiles from -p flags.
func (p *Profile) Set(value string) error {

	if strings.TrimSpace(value) == "" {
		return fmt.Errorf("(empty)")
	}

	for _, k := range *p {
		if k == value {
			return fmt.Errorf("duplicate name: %q", value)
		}
	}

	*p = append(*p, value)

	return nil
}
