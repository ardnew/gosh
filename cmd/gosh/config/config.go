package config

import (
	"fmt"
	"io/ioutil"
	"strings"

	"gopkg.in/yaml.v3"
	// "github.com/juju/errors"
)

// Config represents the parameters to launch and configure the user shell.
type Config struct {
	Shell   string  `yaml:"shell"`
	Args    ArgList `yaml:"args"`
	CmdFlag string  `yaml:"cmdflag"`
	Env     EnvList `yaml:"profile"`
}

// Attr stores the attributes for an individual shell configuration.
type Attr struct {
	Cwd string  `yaml:"cwd"`
	Inc Include `yaml:"include"`
}

// Include contains names of files to be sourced by the shell environment.
type Include []string

// ArgList contains the positional arguments given to the shell command. Do NOT
// include the command at position 0 (as required); it will be added for you.
type ArgList []string

// EnvAttr associates a named directory/profile with an Attr
type EnvAttr map[string]Attr

// EnvList contains the named profiles able to be activated.
type EnvList []EnvAttr

// ParseFile parses the YAML configuration into our tidy struct.
func ParseFile(filePath string) (*Config, error) {
	data, err := ioutil.ReadFile(filePath)
	if err != nil {
		return nil, err
	}
	var config Config
	err = yaml.Unmarshal(data, &config)
	if err != nil {
		return nil, err
	}
	return &config, nil
}

func (cfg *Config) String() string {
	const sep string = ", "
	var sb strings.Builder
	sb.WriteString(fmt.Sprintf("%s%q:%q, %q:%s, %s",
		dictBrace.lhs,
		"shell", cfg.Shell,
		"args", listBrace.encloseJoined(cfg.Args, ", "),
		listBrace.lhs))
	for i, e := range cfg.Env {
		list := []string{}
		for name, attr := range e {
			srcList := make([]string, len(attr.Inc))
			for j, file := range attr.Inc {
				srcList[j] = enquote(file, true)
			}
			list = append(list, fmt.Sprintf("%q:%s", name, listBrace.encloseJoined(srcList, sep)))
		}
		if i > 0 {
			sb.WriteString(sep)
		}
		sb.WriteString(fmt.Sprintf("%s", dictBrace.encloseJoined(list, sep)))
	}
	sb.WriteString(fmt.Sprintf("%s%s", listBrace.rhs, dictBrace.rhs))
	return sb.String()
}
