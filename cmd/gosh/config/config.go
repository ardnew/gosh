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
	Shell string  `yaml:"shell"`
	Args  ArgList `yaml:"args"`
	Env   EnvList `yaml:"env"`
}

// SourceList contains names of files to be sourced by the shell environment.
type SourceList []string

// ArgList contains the positional arguments given to the shell command. Do NOT
// include the command at position 0 (as required); it will be added for you.
type ArgList []string

// Source associates a named directory/environment with a SourceList.
type Source map[string]SourceList

// EnvList contains the named environments able to be sourced.
type EnvList []Source

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
	for i, env := range cfg.Env {
		envList := []string{}
		for name, src := range env {
			srcList := make([]string, len(src))
			for j, file := range src {
				srcList[j] = enquote(file, true)
			}
			envList = append(envList, fmt.Sprintf("%q:%s", name, listBrace.encloseJoined(srcList, sep)))
		}
		if i > 0 {
			sb.WriteString(sep)
		}
		sb.WriteString(fmt.Sprintf("%s", dictBrace.encloseJoined(envList, sep)))
	}
	sb.WriteString(fmt.Sprintf("%s%s", listBrace.rhs, dictBrace.rhs))
	return sb.String()
}
