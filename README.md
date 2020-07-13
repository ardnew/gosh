# gosh

### Easily integrate Go with command-line shell environments

The [`github.com/ardnew/gosh`](https://github.com/ardnew/gosh) repo contains two primary utilities (written in pure Go) designed to **improve the quality of my personal life**.

1. [`cmd/gosh`](https://github.com/ardnew/gosh/tree/master/cmd/gosh) - Launch shell with YAML-driven environment

The `gosh` application dynamically creates an initialization file (e.g., `~/.bashrc`, `~/.zshrc`, etc.) for your shell by including the contents of various traditional shell scripts (e.g., `~/.bash_functions`, `~/.bash_aliases`, etc.) located in a configuration directory and grouped together by named "profile" keys in a YAML configuration file. 

It is very flexible, noninvasive, and requires minimal convention.

2. [`cmd/goshfun`](https://github.com/ardnew/gosh/tree/master/cmd/goshfun) - Generate command-line interface for Go library functions

The intent of `goshfun` is to automatically generate a command-line interface to much of the Go standard library. This means functions like `strings.Join`, `path/filepath.Split`, `math.Min`/`math.Max`, and a vast number of other really useful utilities, some of which not directly available in most modern shells, can be used directly from the command-line, using shell syntax, without having to write and compile any Go code whatsoever.

Interfaces are produced by analyzing function signatures of Go source code located in named packages the user provides to the parser/generator. Once generated, a single executable is produced through which the user can call any library function originally discovered.
