package main

import (
	"fmt"
	"strings"

	"github.com/ardnew/gosh/cmd/gosh/cli"
	"github.com/ardnew/gosh/cmd/gosh/config"
	"github.com/ardnew/gosh/cmd/gosh/exit"
	"github.com/ardnew/gosh/cmd/gosh/log"

	"github.com/ardnew/version"
)

func init() {
	version.ChangeLog = []version.Change{
		{ // initializing project version number in ONE location is fine I guess
			Package: "gosh",
			Version: "0.1.0",
			Date:    "June 30, 2020",
			Description: []string{
				`+ Initial commit`,
			},
		},
		{
			Package: "gosh",
			Version: "0.2.0",
			Date:    "July 17, 2020",
			Description: []string{
				`% Move profile selection to flags, args represent command to run`,
			},
		},
		{
			Package: "gosh",
			Version: "0.3.0",
			Date:    "February 23, 2021",
			Description: []string{
				`+ Add option to print generated init file instead of launching shell`,
				`+ Append shell environment with GOSH_INIT, containing path to init file`,
				`% Default to standard log handler if debug flag provided`,
			},
		},
		{
			Package: "gosh",
			Version: "0.3.1",
			Date:    "March 6, 2021",
			Description: []string{
				`- Move go.mod file to root package path github.com/ardnew/gosh`,
				`% Rename changelog flag from -a to -V`,
			},
		},
		{
			Package: "gosh",
			Version: "0.4.0",
			Date:    "April 19, 2022",
			Description: []string{
				`% Major refactor of configuration YAML format:`,
				`|  + Per-profile initial working directory and env definitions`,
				`|  + (Placeholder stub for profile inheritance)`,
				`|  + Rename GOSH_INIT to GOSH_RCFILE`,
				`|  + Support for multiple shell definitions`,
				`+ Override which shell is executed with flag -e`,
				`% Proper handling of args in non-interactive shells with flag -c`,
			},
		},
		{
			Package: "gosh",
			Version: "0.4.1",
			Date:    "April 20, 2022",
			Description: []string{
				`+ Add support for login/interactive/command shells`,
				`+ Add handling of end-of-options delimiter "--"`,
			},
		},
	}
}

func main() {

	const debugLogHandler = log.LogStandard

	appProp := config.AppProperties{
		PackageName:    "gosh",
		EnvConfigName:  "GOSH_CONFIG",
		FileConfigName: "config.yml",
		ReqShellName:   "auto",
		ReqProfileName: "auto",
		PermConfigFile: 0o600,
		PermConfigDir:  0o700,
	}

	appFlag := config.StartFlags{
		Version: config.BoolFlag{
			Flag:   "v",
			Desc:   "Print application version.",
			Preset: false,
		},
		ChangeLog: config.BoolFlag{
			Flag:   "V",
			Desc:   "Print the application changelog.",
			Preset: false,
		},
		ConfigPath: config.StringFlag{
			Flag:   "f",
			Desc:   "Use an alternate configuration file located at `path`. Profile paths are relative to this configuration file.",
			Preset: appProp.ConfigPath(),
		},
		Shell: config.StringFlag{
			Flag:   "e",
			Desc:   "Use executable and paramter templates named `shell` in configuration file.",
			Preset: appProp.ReqShellName,
		},
		LogHandler: config.StringFlag{
			Flag:   "o",
			Desc:   fmt.Sprintf("Specify the output log `format` [%s].", strings.Join(log.IdentNames(), ", ")),
			Preset: log.LogDefaultIdent.String(),
		},
		DebugEnabled: config.BoolFlag{
			Flag:   "g",
			Desc:   fmt.Sprintf("Enable debug message logging (implies [-o %q] if not provided).", debugLogHandler.String()),
			Preset: false,
		},
		// reversed logic for inherit because I suspect inheriting is the preferred
		// or typical behavior. thus, user adds the flag for atypical behavior.
		OrphanEnviron: config.BoolFlag{
			Flag:   "u",
			Desc:   "Do NOT inherit the environment from current process; or, if generating an init file, do NOT export the current environment.",
			Preset: false,
		},
		GenerateGoshrc: config.BoolFlag{
			Flag:   "d",
			Desc:   "Print the generated goshrc file instead of using it to start a new shell.",
			Preset: false,
		},
		Profiles: config.ProfileFlag{
			Flag: "p",
			Desc: "Load files defined in configuration `profile`; may be specified multiple times.",
		},
		ShellCommand: config.StringFlag{
			Flag:   "c",
			Desc:   "Run `command` directly in a shell; use the \"commandline\" flags defined in configuration file.",
			Preset: "",
		},
		LoginShell: config.BoolFlag{
			Flag:   "l",
			Desc:   "Behave as a login shell; use the \"loginshell\" flags defined in configuration file.",
			Preset: false,
		},
		Interactive: config.BoolFlag{
			Flag:   "i",
			Desc:   "Behave as an interactive shell; use the \"interactive\" flags defined in configuration file.",
			Preset: true,
		},
	}

	config.DebugLogHandler = debugLogHandler.String()

	if param, parsed := appFlag.Parse(&appProp); !parsed {
		exit.FlagsNotParsed.HaltAnnotated(nil, "flags not parsed")
	} else if param.ChangeLog {
		version.PrintChangeLog()
	} else if param.Version {
		fmt.Println(appProp.PackageName, "version", version.String())
	} else if ui, err := cli.Start(param); err != nil {
		exit.CLINotStarted.HaltAnnotated(err, "CLI not started")
	} else if err := ui.CreateShell(); err != nil {
		exit.ShellNotCreated.HaltAnnotated(err, "shell not created")
	}
	exit.OK.Halt()
}
