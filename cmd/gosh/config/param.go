package config

import (
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"unicode"
)

// Default log handler when debug enabled (set in main.go:main).
// These may also be overridden via environment variable GOSH_DEBUG.
// However, priority is always given command-line flags (-o and -w).
var (
	DebugLogHandler string
	DebugLogPath    string
)

// Parameters represents the global configuration of the application, mostly
// defined or initialized by command-line arguments.
type Parameters struct {
	App            AppProperties
	Version        bool
	ChangeLog      bool
	ConfigPath     string
	ShellCommand   string
	LogHandler     string
	LogPath        string
	LogWriter      io.Writer
	DebugEnabled   bool
	OrphanEnviron  bool
	GenerateGoshrc bool
	Shell          string
	ShellArgs      []string
	Profiles       ProfileList
	LoginShell     bool
	Interactive    bool
}

// AppProperties represents constants associated with the running application.
type AppProperties struct {
	PackageName    string
	FileEnvName    string
	EnvDebugName   string
	EnvDebugDelim  string
	EnvConfigName  string
	FileConfigName string
	ReqProfileName string
	ReqShellName   string
	PermConfigFile os.FileMode
	PermConfigDir  os.FileMode
	PermLogFile    os.FileMode
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

// SourceEnvPath provides the path to a file containing environment variable
// key-value pairs to source prior to running.
func (app *AppProperties) SourceEnvPath() string {
	osConfigDir := func() string {
		config, err := os.UserConfigDir()
		if err != nil {
			// path to FreeDesktop's definition of $XDG_CONFIG_HOME
			const configDefault = ".config"
			config = filepath.Join(app.HomeDir(), configDefault)
		}
		return filepath.Join(config, app.PackageName)
	}
	return filepath.Join(osConfigDir(), app.FileEnvName)
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

// ProfileList represents gosh environments to load.
type ProfileList []string

// String constructs a descriptive representation of a ProfileList.
func (p *ProfileList) String() string {
	q := []string{}
	for _, s := range *p {
		q = append(q, fmt.Sprintf("%q", s))
	}
	return fmt.Sprintf("[%s]", strings.Join(q, ", "))
}

// Set implements the flag.Value interface to parse profiles from -p flags.
func (p *ProfileList) Set(value string) error {
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

// StartFlags contains attributes of the pre-defined command-line flags.
type StartFlags struct {
	Version        BoolFlag
	ChangeLog      BoolFlag
	ConfigPath     StringFlag
	ShellCommand   StringFlag
	LogHandler     StringFlag
	LogPath        StringFlag
	DebugEnabled   BoolFlag
	OrphanEnviron  BoolFlag
	GenerateGoshrc BoolFlag
	Shell          StringFlag
	Profiles       ProfileFlag
	LoginShell     BoolFlag
	Interactive    BoolFlag
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
func (sf *StartFlags) Parse(app *AppProperties) (*Parameters, bool, error) {

	param := Parameters{App: *app, ShellArgs: []string{}}

	fl := flag.NewFlagSet(app.PackageName, flag.ExitOnError)

	fl.BoolVar(&param.Version, sf.Version.Flag, sf.Version.Preset, sf.Version.Desc)
	fl.BoolVar(&param.ChangeLog, sf.ChangeLog.Flag, sf.ChangeLog.Preset, sf.ChangeLog.Desc)
	fl.StringVar(&param.ConfigPath, sf.ConfigPath.Flag, sf.ConfigPath.Preset, sf.ConfigPath.Desc)
	fl.StringVar(&param.ShellCommand, sf.ShellCommand.Flag, sf.ShellCommand.Preset, sf.ShellCommand.Desc)
	fl.StringVar(&param.Shell, sf.Shell.Flag, sf.Shell.Preset, sf.Shell.Desc)
	fl.Var(&param.Profiles, sf.Profiles.Flag, sf.Profiles.Desc)
	fl.StringVar(&param.LogHandler, sf.LogHandler.Flag, sf.LogHandler.Preset, sf.LogHandler.Desc)
	fl.StringVar(&param.LogPath, sf.LogPath.Flag, sf.LogPath.Preset, sf.LogPath.Desc)
	fl.BoolVar(&param.DebugEnabled, sf.DebugEnabled.Flag, sf.DebugEnabled.Preset, sf.DebugEnabled.Desc)
	fl.BoolVar(&param.OrphanEnviron, sf.OrphanEnviron.Flag, sf.OrphanEnviron.Preset, sf.OrphanEnviron.Desc)
	fl.BoolVar(&param.GenerateGoshrc, sf.GenerateGoshrc.Flag, sf.GenerateGoshrc.Preset, sf.GenerateGoshrc.Desc)
	fl.BoolVar(&param.LoginShell, sf.LoginShell.Flag, sf.LoginShell.Preset, sf.LoginShell.Desc)
	fl.BoolVar(&param.Interactive, sf.Interactive.Flag, sf.Interactive.Preset, sf.Interactive.Desc)

	argv := []string{}
	parg := &argv
	for _, a := range os.Args[1:] {
		if a == "--" {
			parg = &param.ShellArgs
		} else {
			*parg = append(*parg, a)
		}
	}
	fl.Parse(argv)

	// Prepend the unhandled arguments preceding end of argument list "--" to
	// those following it.
	param.ShellArgs = append(fl.Args(), param.ShellArgs...)

	// create a map of all flags actually provided by the user
	type values []flag.Value
	given := map[string]values{}
	fl.Visit(func(f *flag.Flag) {
		if _, ok := given[f.Name]; !ok {
			given[f.Name] = values{}
		}
		given[f.Name] = append(given[f.Name], f.Value)
	})

	_, handlerGiven := given[sf.LogHandler.Flag]
	_, pathGiven := given[sf.LogPath.Flag]

	if param.DebugEnabled {
		// DebugLogHandler and DebugLogWriter are set in main.go:main(), and they
		// are the default handler/writer when only the debug flag (-g) is given.
		if !handlerGiven {
			param.LogHandler = DebugLogHandler
		}
		if !pathGiven {
			param.LogPath = DebugLogPath
		}
	}

	if !param.DebugEnabled && !pathGiven {
		param.LogWriter = io.Discard
	} else {
		path, oflg := parseOpenFlag(param.LogPath)
		switch path[0] {
		case '-':
			param.LogWriter = os.Stdout
		case '+':
			param.LogWriter = os.Stderr
		default:
			wo, err := os.OpenFile(path, oflg, os.ModePerm&app.PermLogFile)
			if err != nil {
				return &param, fl.Parsed(), err
			}
			param.LogWriter = wo
		}
	}

	return &param, fl.Parsed(), nil
}

func parseOpenFlag(modePath string) (string, int) {
	prefix, carets := true, 0
	path := strings.TrimLeftFunc(modePath, func(r rune) bool {
		if prefix {
			if r == '>' && carets < 2 {
				carets++
			} else {
				prefix = unicode.IsSpace(r)
			}
		}
		return prefix
	})
	oflg := os.O_WRONLY | os.O_CREATE
	if carets == 2 {
		oflg |= os.O_APPEND
	}
	return path, oflg
}
