package log

import (
	"fmt"
	"io"
	"os"

	"github.com/ardnew/gosh/cmd/gosh/config"

	"github.com/apex/log"
	"github.com/apex/log/handlers/cli"
	"github.com/apex/log/handlers/discard"
	"github.com/apex/log/handlers/json"
	"github.com/apex/log/handlers/text"
	// "github.com/juju/errors"
)

// Handler exposes the primary logging interface to main. Right now we depend on
// the current logging library, need to encapsulate its functionality.
// See below: Context()
type Handler struct {
	id  Ident
	ctx log.Interface
}

// NewHandler generates a logging interface based on user's given parameters.
func NewHandler(out io.Writer, param *config.Parameters) *Handler {

	id := ParseIdent(param.LogHandler)

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
	if param.DebugEnabled {
		log.SetLevel(log.DebugLevel)
		ctx = log.WithFields(log.Fields{
			"proc": "gosh",
			"pid":  fmt.Sprintf("%d", os.Getpid()),
		})
	} else {
		log.SetLevel(log.InfoLevel)
		ctx = log.WithFields(log.Fields{})
	}

	return &Handler{id: id, ctx: ctx}
}

// Context exposes the actual logging library to main. **Ta-da!!
func (lh *Handler) Context() log.Interface {
	return lh.ctx
}
