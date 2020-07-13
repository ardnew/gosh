# cmd/gosh
### Launch shell with YAML-driven environment

## Usage

The `gosh` application dynamically creates an initialization file (e.g. `~/.bashrc`, `~/.zshrc`) for your shell by including the contents of various shell scripts located in directory `~/.config/gosh`. You indicate which files get included by configuring the YAML file located at `~/.config/gosh/config.yml` (or specified with `-c` flag).

Regardless of additional arguments, `gosh` will *always* include the files listed under the `auto` key in the configuration YAML file, so make sure its contents are universally applicable to all profiles you intend to define. 

You can add other keys besides `auto` to have custom shell "profiles", which is useful if you need to change `$PATH` (for various cross-compiler environments, for example), or you want a fancy `$PS1` for different `tmux`/`screen` sessions. 

To specify which profiles to load, simply name them as arguments at invocation, e.g, `gosh arduino` will load the files listed under the `arduino` key defined in `config.yml`, and found in subdirectory `~/.config/gosh/arduino`. (Remember, it also always imports first the files defined under `auto` and found in `~/.config/gosh/auto`.)

Also in `config.yml`, there are options for specifying which shell to launch (`/bin/bash`, `/bin/zsh`, etc.) along with their associated startup flags.

## Quickstart

You simply call `gosh [profile]` from your existing shell to start a new session (see [Usage](#Usage) above for info about profiles).

> If you're ***hardcore*** like me, you can also replace your login shell (e.g., `/bin/bash` in `/etc/passwd`) with `/path/to/gosh` to let it always manage your shell.

Just to get up and running, I recommend using the [demo included with this repo](https://github.com/ardnew/gosh/tree/master/config/). Installation is easy:

1. Install package: `go get -v github.com/ardnew/gosh/cmd/gosh`

2. Copy the contents of [`$GOPATH/src/github.com/ardnew/gosh/config/`](https://github.com/ardnew/gosh/tree/master/config/) into `~/.config/gosh`.

3. Execute `gosh`, and you should see a familiar shell, but what you don't see is that it is being managed by a Go application! 

To see we are a Go sub-process, re-run `gosh` with the following arguments, `gosh -l standard -g`, and you'll see the `gosh` runtime spewing out some debugging information regarding how the shell process was spawned. You'll see more once you close the shell (via `exit` or `^D`)

All available command-line arguments:

|Flag name|Type|Description|
|:--:|:--:|:----------|
|`-c`|`string`|path to the primary configuration file (default `~/.config/gosh/config.yml`)|
|`-g`|`bool`|enable debug message logging|
|`-l`|`string`|output log handler (`null`, `standard`, `ascii`, `json`) (default `null`)|
|`-o`|`bool`|do NOT inherit the environment from current process, i.e., orphan|

## Configuration

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
