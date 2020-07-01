package main

// Config represents the parameters to launch and configure the user shell.
type Config struct {
	Shell   string            `json:shell`
	Init    []string          `json:init`
	Profile map[string]string `json:profile`
}
