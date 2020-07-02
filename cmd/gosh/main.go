package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/ardnew/gosh/cmd/gosh/config"
	"github.com/ardnew/gosh/cmd/gosh/log"

	apexLog "github.com/apex/log"
	"github.com/ardnew/version"
)

const (
	packageName    = "gosh"
	envConfigName  = "GOSH_CONFIG"
	fileConfigName = "config.yml"
	permConfigFile = 0o600
	permConfigDir  = 0o700
)

func init() { // NOT FOR PROGRAM LOGIC
	version.ChangeLog = []version.Change{
		{ // initializing project version number in ONE location is fine I guess
			Package: packageName,
			Version: "0.1.0",
			Date:    "June 30, 2020",
			Description: []string{
				`initial commit`,
			},
		},
	}
}

type parameters struct {
	configPath string
	logHandler string
	debug      bool
}

func start() *parameters {
	var param parameters
	flag.StringVar(&param.configPath, "c", configPathDefault(),
		fmt.Sprintf("path to the primary configuration file"))
	flag.StringVar(&param.logHandler, "l", log.LogDefaultIdent.String(),
		fmt.Sprintf("output log handler (%s)", strings.Join(log.IdentNames(), ", ")))
	flag.BoolVar(&param.debug, "g", false,
		fmt.Sprintf("enable debug message logging"))
	flag.Parse()
	return &param
}

func main() {

	if param := start(); flag.Parsed() {

		var (
			err error
			cfg *config.Config
		)

		out := log.NewHandler(os.Stdout, param.logHandler, param.debug)

		defer out.Interface().WithFields(apexLog.Fields{
			"config": param.configPath,
		}).Trace("initialization").Stop(&err)

		if err = os.MkdirAll(filepath.Dir(param.configPath), permConfigDir); err != nil {
			return
		}

		cfg, err = config.ParseFile(param.configPath)
		if err == nil {
			out.Interface().WithField("cfg", cfg.String()).Debug("parsed configuration")
		}
	}
}

func configPathDefault() string {
	osConfigDir := func() string {
		const configDefault = ".config"
		config, err := os.UserConfigDir()
		if err != nil {
			config = filepath.Join(homeDir(), configDefault)
		}
		return filepath.Join(config, packageName)
	}
	if config, found := os.LookupEnv(envConfigName); found {
		return config
	}
	return filepath.Join(osConfigDir(), fileConfigName)
}

func homeDir() string {
	if home, err := os.UserHomeDir(); err == nil {
		return home
	}
	if home, err := os.Getwd(); err == nil {
		return home
	}
	return "."
}
