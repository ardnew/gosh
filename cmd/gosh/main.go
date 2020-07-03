package main

import (
	"flag"
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
				`initial commit`,
			},
		},
	}
}

func main() {

	appProp := config.AppProperties{
		PackageName:    "gosh",
		EnvConfigName:  "GOSH_CONFIG",
		FileConfigName: "config.yml",
		ReqEnvName:     "auto",
		PermConfigFile: 0o600,
		PermConfigDir:  0o700,
	}

	appFlag := config.StartFlags{
		ConfigPath: config.StringFlag{
			Flag:   "c",
			Desc:   fmt.Sprintf("path to the primary configuration file"),
			Preset: appProp.ConfigPath(),
		},
		LogHandler: config.StringFlag{
			Flag:   "l",
			Desc:   fmt.Sprintf("output log handler (%s)", strings.Join(log.IdentNames(), ", ")),
			Preset: log.LogDefaultIdent.String(),
		},
		DebugEnabled: config.BoolFlag{
			Flag:   "g",
			Desc:   "enable debug message logging",
			Preset: false,
		},
	}

	if param := appFlag.Parse(&appProp); !flag.Parsed() {
		exit.ExitFlagsNotParsed.HaltAnnotated(nil, "flags not parsed")
	} else {
		if ui, err := cli.Start(param); err != nil {
			exit.ExitCLINotStarted.HaltAnnotated(err, "CLI not started")
		} else {
			if err := ui.CreateShell(); err != nil {
				exit.ExitShellNotCreated.HaltAnnotated(err, "shell not created")
			}
		}
	}
	exit.ExitOK.Halt()
}
