package exit

import (
	"fmt"
	"os"

	"github.com/juju/errors"
)

// Code represents a program termination exit code.
type Code int

// Constant enumerated values of type Code.
const (
	OK              Code = 0
	FlagsNotParsed  Code = 1
	CLINotStarted   Code = 2
	ShellNotCreated Code = 3
	InvalidFlags    Code = 4
)

// Halt terminates program execution with the receiver's exit code.
func (c Code) Halt() {
	c.HaltAnnotated(nil, "")
}

// HaltAnnotated terminates program execution with the receiver's exit code and
// an annotated error message.
func (c Code) HaltAnnotated(err error, note string) {
	haltMessage := ""
	switch c {
	case OK:
		if "" != note {
			haltMessage = fmt.Sprintf("halt(%d): %s", c, note)
		}
	default:
		var res error
		if err == nil {
			if "" == note {
				note = "unknown error"
			}
			res = fmt.Errorf("%s", note)
		} else {
			if "" != note {
				res = errors.Annotate(err, note)
			}
		}
		haltMessage = fmt.Sprintf("halt(%d): %v", c, res)
	}
	if "" != haltMessage {
		fmt.Fprintf(os.Stderr, "\n%s\n", haltMessage)
	}
	os.Exit(int(c))
}
