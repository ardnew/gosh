# gosh
#### Easily integrate Go with command-line shell environments

The [`github.com/ardnew/gosh`](https://github.com/ardnew/gosh) repo contains two primary utilities (written in pure Go) designed to **improve the quality of my personal life**.

[*Currently*](#future-work), these utilities, namely `gosh` and `goshfun` are intended for use as standlone executables.

---

## 1. [`gosh`](https://github.com/ardnew/gosh/cmd/gosh) 

#### Quickstart
Ideally, you simply replace your login shell (e.g. `/bin/bash` in `/etc/fstab`) with `/path/to/gosh`, and then configure the gosh runtime. 

Just to get up and running, I recommend using the [demo included with this repo](https://github.com/ardnew/gosh/config): 

1. Copy the contents of [config](https://github.com/ardnew/gosh/config) into `~/.config/gosh`.

2. Execute `gosh`, and you should see a familiar shell, but what you don't see is that it is being managed by a Go application! 

To see we are a Go sub-process, re-run `gosh` with the following arguments, `gosh -l standard -g`, and you'll see the `gosh` runtime spewing out some debugging information regarding how the shell process was spawned. You'll see more once you close the shell (via `exit` or `^D`)

Available command-line arguments:

|Flag|Type|Description|
|:--:|:--:|:----------|
|`-c`|`string`|path to the primary configuration file (default `~/.config/gosh/config.yml`)|
|`-g`|`bool`|enable debug message logging|
|`-l`|`string`|output log handler (`null`, `standard`, `ascii`, `json`) (default `null`)|
|`-o`|`bool`|do NOT inherit the environment from current process, i.e., orphan|

#### Configuration
The `gosh` application dynamically creates an initialization file (e.g. `~/.bashrc`, `~/.zshrc`) for your shell by including the contents of various shell scripts located in `~/.config/gosh`. You indicate which files get included by configuring the YAML file located at `~/.config/gosh/config.yml` (or specified with `-c PATH` argument).

Regardless of additional arguments, `gosh` will always include the files listed under the `auto` key in the configuration YAML file. You can add other keys besides `auto` to have custom shell "profiles", which is useful if you need to change `$PATH` (for various cross-compiler environments, for example), or you want a fancy `$PS1` for different `tmux` or `screen` sessions. 

To specify which profiles to load, simply name them as arguments at invocation, i.e. `gosh PROFILE`. The `arduino` key in the demo configuration file is an example.

---

## 2. [`goshfun`](https://github.com/ardnew/gosh/cmd/goshfun) 

#### Quickstart
> **TBD**

