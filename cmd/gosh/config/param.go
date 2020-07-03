package config

import (
	"flag"
	"os"
	"path/filepath"
	// "github.com/juju/errors"
)

// Parameters represents the global configuration of the application, mostly
// defined or initialized by command-line arguments.
type Parameters struct {
	App          AppProperties
	ConfigPath   string
	LogHandler   string
	DebugEnabled bool
	SelEnvName   string
}

// StartFlags contains attributes of the pre-defined command-line flags.
type StartFlags struct {
	ConfigPath   StringFlag
	LogHandler   StringFlag
	DebugEnabled BoolFlag
}

// StringFlag contains the attributes of a string type command-line flag.
type StringFlag struct {
	Flag   string
	Desc   string
	Preset string
}

// BoolFlag contains the attributes of a bool type command-line flag.
type BoolFlag struct {
	Flag   string
	Desc   string
	Preset bool
}

// Parse initializes the default flagset and parses command-line flags into the
// shareable Parameters struct.
func (sf *StartFlags) Parse(app *AppProperties) *Parameters {
	param := Parameters{App: *app}
	flag.StringVar(&param.ConfigPath, sf.ConfigPath.Flag, sf.ConfigPath.Preset, sf.ConfigPath.Desc)
	flag.StringVar(&param.LogHandler, sf.LogHandler.Flag, sf.LogHandler.Preset, sf.LogHandler.Desc)
	flag.BoolVar(&param.DebugEnabled, sf.DebugEnabled.Flag, sf.DebugEnabled.Preset, sf.DebugEnabled.Desc)
	flag.Parse()
	if len(flag.Args()) > 0 {
		param.SelEnvName = flag.Arg(0)
	} else {
		param.SelEnvName = app.ReqEnvName
	}
	return &param
}

// AppProperties represents constants associated with the running application.
type AppProperties struct {
	PackageName    string
	EnvConfigName  string
	FileConfigName string
	ReqEnvName     string
	PermConfigFile os.FileMode
	PermConfigDir  os.FileMode
}

// ConfigPath provides the default YAML configuration file path when not
// overridden by the user via command-line Parameters.
func (app *AppProperties) ConfigPath() string {
	osConfigDir := func() string {
		config, err := os.UserConfigDir()
		if err != nil {
			// path to FreeDesktop's definition of $XDG_CONFIG_HOME
			const configDefault = ".config"
			config = filepath.Join(app.HomeDir(), configDefault)
		}
		return filepath.Join(config, app.PackageName)
	}
	if config, found := os.LookupEnv(app.EnvConfigName); found {
		return config
	}
	return filepath.Join(osConfigDir(), app.FileConfigName)
}

// HomeDir provides an absolute path to the user's home directory. Note that if
// no $HOME dir can be determined, the current working dir is returned.
func (app *AppProperties) HomeDir() string {
	path := "."
	if home, err := os.UserHomeDir(); err == nil {
		path = home
	} else if home, err := os.Getwd(); err == nil {
		path = home
	}
	if abs, err := filepath.Abs(path); err == nil {
		return abs
	}
	return path
}
