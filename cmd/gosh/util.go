package main

import (
	"os"
	"path/filepath"
)

func osHomeDir() string {
	if home, err := os.UserHomeDir(); err == nil {
		return home
	}
	if home, err := os.Getwd(); err == nil {
		return home
	}
	return "."
}

func osConfigDir() string {
	const configDefault = ".config"
	config, err := os.UserConfigDir()
	if err != nil {
		config = filepath.Join(osHomeDir(), configDefault)
	}
	return filepath.Join(config, packageName)
}
