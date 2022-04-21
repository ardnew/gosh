package config

import (
	"fmt"
	"io/ioutil"

	"gopkg.in/yaml.v3"
	// "github.com/juju/errors"
)

// Config represents the parameters to launch and configure the user shell.
type Config struct {
	Shell   Shells   `yaml:"shell"`
	Profile Profiles `yaml:"profile"`
}

// Shell defines the configuration attributes for a given shell.
//
// Exec is the absolute file path to the shell executable, and Flag defines the
// positional arguments used with various invocation methods.
type Shell struct {
	Exec string `yaml:"exec"`
	Flag Flags  `yaml:"flag"`
}

// Flags defines the template argument lists passed to the shell.
type Flags struct {
	CommandLine []string `yaml:"commandline,flow"`
	Interactive []string `yaml:"interactive,flow"`
	LoginShell  []string `yaml:"loginshell,flow"`
}

// Shells maps names of shells to their respective configuration attributes.
type Shells map[string]Shell

// Profile defines the configuration attributes for a shell profile.
type Profile struct {
	Cwd     string   `yaml:"cwd,omitempty"`
	Env     []string `yaml:"env,omitempty"`
	Inherit []string `yaml:"inherit,flow,omitempty"`
	Include []string `yaml:"include,omitempty"`
}

// Profiles maps names of profiles to their respective configuration attributes.
type Profiles map[string]Profile

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

// String returns a string representation of the receiver Config.
func (cfg Config) String() string {
	return fmt.Sprintf("{Shell:%+v Profile:%+v}", cfg.Shell, cfg.Profile)
}

func (pro Profile) String() string {
	return fmt.Sprintf("{Cwd:%s Include:%+v}", pro.Cwd, pro.Include)
}
