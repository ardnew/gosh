package log

import (
	"fmt"
	"io"
	"os"

	"github.com/apex/log"
	"github.com/apex/log/handlers/cli"
	"github.com/apex/log/handlers/discard"
	"github.com/apex/log/handlers/json"
	"github.com/apex/log/handlers/text"
)

// Handler exposes the primary logging interface to main. Right now we depend on
// the current logging library, need to encapsulate its functionality.
type Handler struct {
	id  Ident
	ctx log.Interface
}

// NewHandler generates a logging interface based on user's given parameters.
func NewHandler(out io.Writer, handler string, debug bool) *Handler {

	id := ParseIdent(handler)

	switch id {
	case LogNull:
		log.SetHandler(discard.New())
	case LogStandard:
		log.SetHandler(cli.New(out))
	case LogASCII:
		log.SetHandler(text.New(out))
	case LogJSON:
		log.SetHandler(json.New(out))
	}

	var ctx log.Interface
	if debug {
		log.SetLevel(log.DebugLevel)
		ctx = log.WithFields(log.Fields{
			"proc": "gosh",
			"pid":  fmt.Sprintf("0x%08X", os.Getpid()),
		})
	} else {
		log.SetLevel(log.InfoLevel)
		ctx = log.WithFields(log.Fields{})
	}

	return &Handler{id: id, ctx: ctx}
}

// Interface exposes the actual logging library to main.
func (lh *Handler) Interface() log.Interface {
	return lh.ctx
}
