package config

import (
	"fmt"
	"strings"
)

type encloser struct {
	lhs string
	rhs string
}

var (
	listBrace = encloser{lhs: "[", rhs: "]"}
	dictBrace = encloser{lhs: "{", rhs: "}"}
)

func (br *encloser) encloseJoined(ls []string, jn string) string {
	return fmt.Sprintf("%s%s%s", br.lhs, strings.Join(ls, jn), br.rhs)
}

func enquote(str string, enq bool) string {
	const quote rune = '"'
	var sb strings.Builder
	if enq && !strings.HasPrefix(str, string(quote)) {
		sb.WriteRune(quote)
	}
	sb.WriteString(str)
	if enq && !strings.HasSuffix(str, string(quote)) {
		sb.WriteRune(quote)
	}
	return sb.String()
}
