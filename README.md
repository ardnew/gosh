# gosh

#### Easily integrate Go with command-line shell environments

The [`github.com/ardnew/gosh`](https://github.com/ardnew/gosh) repo contains two primary utilities (written in pure Go) designed to **improve the quality of my personal life**.

[*Currently*](#future-work), these utilities, namely `gosh` and `goshfun` are intended for use as standlone executables.

---

## 1. [`gosh`](https://github.com/ardnew/gosh/cmd/gosh) 

### Usage

The `gosh` application dynamically creates an initialization file (e.g. `~/.bashrc`, `~/.zshrc`) for your shell by including the contents of various shell scripts located in directory `~/.config/gosh`. You indicate which files get included by configuring the YAML file located at `~/.config/gosh/config.yml` (or specified with `-c` flag).

Regardless of additional arguments, `gosh` will *always* include the files listed under the `auto` key in the configuration YAML file, so make sure its contents are universally applicable to all profiles you intend to define. 

You can add other keys besides `auto` to have custom shell "profiles", which is useful if you need to change `$PATH` (for various cross-compiler environments, for example), or you want a fancy `$PS1` for different `tmux`/`screen` sessions. 

To specify which profiles to load, simply name them as arguments at invocation, e.g, `gosh arduino` will load the files listed under the `arduino` key defined in `config.yml`, and found in subdirectory `~/.config/gosh/arduino`. (Remember, it also always imports first the files defined under `auto` and found in `~/.config/gosh/auto`.)

Also in `config.yml`, there are options for specifying which shell to launch (`/bin/bash`, `/bin/zsh`, etc.) along with their associated startup flags.

### Quickstart

You simply call `gosh [profile]` from your existing shell to start a new session (see [Usage](https://github.com/ardnew/gosh/README.md#usage) above for info about profiles).

> If you're ***hardcore*** like me, you can also replace your login shell (e.g., `/bin/bash` in `/etc/passwd`) with `/path/to/gosh` to let it always manage your shell.

Just to get up and running, I recommend using the [demo included with this repo](https://github.com/ardnew/gosh/config). Installation is easy:

1. Install package: `go get -v github.com/ardnew/gosh/cmd/gosh`

2. Copy the contents of [$GOPATH/src/github.com/ardnew/gosh/config/](https://github.com/ardnew/gosh/config) into `~/.config/gosh`.

3. Execute `gosh`, and you should see a familiar shell, but what you don't see is that it is being managed by a Go application! 

To see we are a Go sub-process, re-run `gosh` with the following arguments, `gosh -l standard -g`, and you'll see the `gosh` runtime spewing out some debugging information regarding how the shell process was spawned. You'll see more once you close the shell (via `exit` or `^D`)

All available command-line arguments:

|Flag name|Type|Description|
|:--:|:--:|:----------|
|`-c`|`string`|path to the primary configuration file (default `~/.config/gosh/config.yml`)|
|`-g`|`bool`|enable debug message logging|
|`-l`|`string`|output log handler (`null`, `standard`, `ascii`, `json`) (default `null`)|
|`-o`|`bool`|do NOT inherit the environment from current process, i.e., orphan|

### Configuration

The following example configuration file demonstrates **a.**) how to specify which shell to invoke, **b.**) how to add flags to it (and how to refer to the dynamically-generated initialization script, **c.**) how to define a profile (and its directory name), and **d.**) how to define which files to include when loading a profile.

```yaml
---
shell: /bin/bash                    #   (a.)
args: [ --rcfile, __GOSH_INIT__ ]   #   (b.)
env:
  - auto:                           #   (c.)
    - host.bash                     #   (d.)
    - paths.bash                    #   (d.)
    - terminal.bash                 #   ...
    - colors.bash
    - functions.bash
    - aliases.bash
    - prompt.bash
    - completion.bash
  - arduino:                        #   (c.)
    - arduino-cli.bash              #   (d.)
  - segger:                         #   (c.)
    - segger-jlink.bash             #   (d.)

```
---

## 2. [`goshfun`](https://github.com/ardnew/gosh/cmd/goshfun) 

The `goshfun` utility is an altogether different beast, but for the purpose of integrating Go with shell environments, it makes sense to include it with the `gosh` project.

The intent of `goshfun` is to automatically generate a command-line interface to much of the Go standard library. This means functions like `strings.Join`, `path/filepath.Split`, `math.Min`/`math.Max`, and a vast number of other really useful utilities, some of which not directly available in most modern shells, can be used directly from the command-line, using shell syntax, without having to write and compile any Go code whatsoever.

### Quickstart

Running `goshfun` without any arguments will generate shell interfaces for the default packages `strings`, `math`, and `path/filepath`.

1. Install package: `go get -v github.com/ardnew/gosh/cmd/goshfun`

2. Generate Go source code and build for default packages: `goshfun` (by default this will generate an executable in directory `./fun`)

At this point you now have a shell interface for all of the functions it printed during generation. You can review those functions by just running `fun` without any arguments (or run `fun -h`).

### Usage

There are two ways to invoke one of the Go library functions packaged into the `fun` executable:

1. Use the `-f` flag:

Provide the function name as argument to the `-f` flag as either its base name, exported name, or fully-qualified package export name (replace slashes `/` with periods `.`). For example, the library function `path/filepath.Split` can be called as any of the following: `fun -f Split`, `fun -f filepath.Split`, or `fun -f path.filepath.Split`. 

Note that the base function name `Split` exists in multiple packages (`strings` and `path/filepath`). Currently, no attempt is made to normalize which package is resolved, so simply using `Split` may invoke either one of these functions. Qualify the function with a package name to prevent ambiguous behavior.

2. Symlink the function name:

Alternatively, in the same spirit as Busybox, you can create a symlink whose name matches the desired function pointing to the `fun` executable. Calling the symlink will call the function with matching name. Using the previous example `path/filepath.Split`, you can create any one of the following symlinks: `ln -s fun Split`, `ln -s fun filepath.Split`, or `ln -s fun path.filepath.Split`. Then simply calling the symlink, e.g., `filepath.Split`, is effectively the same as calling `fun -f filepath.Split`.

The same condition regarding ambiguous function names mentioned above applies to symlinks as well.

All available command-line arguments for `goshfun`:

|Flag name|Type|Description|
|:--:|:--:|:----------|
|`-out`|`string`|generated Go source will be written to file `DIR/main.go` (default `fun`)|
|`-pkg`|`string`|generate interfaces for functions from package path. may be specified multiple times. (default `strings`,`math`,`path/filepath`)|
|`-root`|`string`|path to GOROOT (must contain src) (default `/usr/local/src/go/goroot`)|

And all available command-line arguments for the `goshfun`-generated executable (`fun` by default):

|Flag name|Type|Description|
|:--:|:--:|:----------|
|`-0`|`bool`|delimit ouput parameters with a null byte (`\0`) instead of a newline (`\n`).|
|`-f`|`string`|func invoke function named `FUNC`|
