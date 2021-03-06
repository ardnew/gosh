package config

import (
	"flag"
	"os"
	"path/filepath"
	// "github.com/juju/errors"
)

// default log handler when debug enabled (set in main.go:main)
var DebugLogHandler string

// Parameters represents the global configuration of the application, mostly
// defined or initialized by command-line arguments.
type Parameters struct {
	App           AppProperties
	Version       bool
	ChangeLog     bool
	ConfigPath    string
	ShellCommand  string
	LogHandler    string
	DebugEnabled  bool
	OrphanEnviron bool
	GenerateInit  bool
	Profiles      Profile
	ShellArgs     []string
}

// StartFlags contains attributes of the pre-defined command-line flags.
type StartFlags struct {
	Version       BoolFlag
	ChangeLog     BoolFlag
	ConfigPath    StringFlag
	ShellCommand  StringFlag
	LogHandler    StringFlag
	DebugEnabled  BoolFlag
	OrphanEnviron BoolFlag
	GenerateInit  BoolFlag
	Profiles      ProfileFlag
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

// ProfileFlag contains the attributes of a Profile type command-line flag.
type ProfileFlag struct {
	Flag string
	Desc string
}

// Parse initializes the default flagset and parses command-line flags into the
// shareable Parameters struct.
func (sf *StartFlags) Parse(app *AppProperties) *Parameters {

	param := Parameters{App: *app}

	flag.BoolVar(&param.Version, sf.Version.Flag, sf.Version.Preset, sf.Version.Desc)
	flag.BoolVar(&param.ChangeLog, sf.ChangeLog.Flag, sf.ChangeLog.Preset, sf.ChangeLog.Desc)
	flag.StringVar(&param.ConfigPath, sf.ConfigPath.Flag, sf.ConfigPath.Preset, sf.ConfigPath.Desc)
	flag.StringVar(&param.ShellCommand, sf.ShellCommand.Flag, sf.ShellCommand.Preset, sf.ShellCommand.Desc)
	flag.Var(&param.Profiles, sf.Profiles.Flag, sf.Profiles.Desc)
	flag.StringVar(&param.LogHandler, sf.LogHandler.Flag, sf.LogHandler.Preset, sf.LogHandler.Desc)
	flag.BoolVar(&param.DebugEnabled, sf.DebugEnabled.Flag, sf.DebugEnabled.Preset, sf.DebugEnabled.Desc)
	flag.BoolVar(&param.OrphanEnviron, sf.OrphanEnviron.Flag, sf.OrphanEnviron.Preset, sf.OrphanEnviron.Desc)
	flag.BoolVar(&param.GenerateInit, sf.GenerateInit.Flag, sf.GenerateInit.Preset, sf.GenerateInit.Desc)
	flag.Parse()

	// create a map of all flags actually provided by the user
	type values []flag.Value
	given := map[string]values{}
	flag.Visit(func(f *flag.Flag) {
		if _, ok := given[f.Name]; !ok {
			given[f.Name] = values{}
		}
		given[f.Name] = append(given[f.Name], f.Value)
	})

	// if debug flag given and no log handler specified, use standard log handler
	if param.DebugEnabled && ("" != DebugLogHandler) {
		if _, logGiven := given[sf.LogHandler.Flag]; !logGiven {
			param.LogHandler = DebugLogHandler
		}
	}

	param.ShellArgs = make([]string, 0, len(flag.Args()))
	param.ShellArgs = append(param.ShellArgs, flag.Args()...)

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
