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
|:-------:|:--:|:----------|
|`-a`|`bool`|Print the application changelog.|
|`-c`|`string`|Run **command** with modified environment instead of starting a new shell.|
|`-f`|`string`|Use an alternate configuration file located at **path**. Profile paths are relative to this configuration file. (default `${HOME}/.config/gosh/config.yml`)|
|`-g`|`bool`|Enable debug message logging (implies [`-l "standard"`] unless log format specified).|
|`-l`|`string`|Specify the output log **format** [`null`, `standard`, `ascii`, `json`]. (default `null`)|
|`-o`|`bool`|Do NOT inherit (i.e., orphan) the environment from current process; or, if generating an init file, do NOT export the current environment.|
|`-p`|`string`|Load files defined in configuration **profile**; may be specified multiple times.|
|`-s`|`bool`|Print the generated init file instead of using it to start a new shell.|
|`-v`|`bool`|Print application version.|

## Configuration

The following is an example configuration file that demonstrates how to: 

 1. Specify which shell to invoke
 2. Add command-line flags to your real shell (and how to refer to the dynamically-generated initialization script) 
 3. Define a profile (and its directory name)
 4. Define which files to include when loading a profile

```yaml
---
shell: /bin/bash                    #   (1.)
args: [ --rcfile, __GOSH_INIT__ ]   #   (2.)
env:
  - auto:                           #   (3.)
    - host.bash                     #   (4.)
    - paths.bash                    #   (4.)
    - terminal.bash                 #   ...
    - colors.bash
    - functions.bash
    - aliases.bash
    - prompt.bash
    - completion.bash
  - arduino:                        #   (3.)
    - arduino-cli.bash              #   (4.)
  - segger:                         #   (3.)
    - segger-jlink.bash             #   (4.)

```

