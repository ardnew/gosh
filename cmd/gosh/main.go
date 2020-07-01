package main

import (
	"flag"
	"os"
	"path/filepath"

	"github.com/ardnew/version"
)

const (
	packageName    = "gosh"
	envConfigName  = "GOSH_CONFIG"
	fileConfigName = "config.json"
	permConfigFile = 0o600
	permConfigDir  = 0o700
)

func init() {
	version.ChangeLog = []version.Change{
		{
			Package: packageName,
			Version: "0.1.0",
			Date:    "June 30, 2020",
			Description: []string{
				`initial commit`,
			},
		},
	}

	flag.StringVar(&args.configPath, "c", configPathDefault(), "path to the primary configuration file")
	flag.Parse()
}

var args struct {
	configPath string
}

func main() {

	if flag.Parsed() {
		_, _ = configDir(args.configPath)
	}
}

func configPathDefault() string {
	if config, found := os.LookupEnv(envConfigName); found {
		return config
	}
	return filepath.Join(osConfigDir(), fileConfigName)
}

func configDir(configPath string) (string, error) {
	dir := filepath.Dir(configPath)
	return dir, os.MkdirAll(dir, permConfigDir)
}
