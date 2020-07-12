# gosh

#### Easily integrate Go with command-line shell environments

The [`github.com/ardnew/gosh`](https://github.com/ardnew/gosh) repo contains two primary utilities (written in pure Go) designed to **improve the quality of my personal life**.

*Currently*, these utilities, namely `gosh` and `goshfun` are intended for use as standlone executables.

---

## 1. [`gosh`](https://github.com/ardnew/gosh/tree/master/cmd/gosh) 

### Usage

The `gosh` application dynamically creates an initialization file (e.g. `~/.bashrc`, `~/.zshrc`) for your shell by including the contents of various shell scripts located in directory `~/.config/gosh`. You indicate which files get included by configuring the YAML file located at `~/.config/gosh/config.yml` (or specified with `-c` flag).

Regardless of additional arguments, `gosh` will *always* include the files listed under the `auto` key in the configuration YAML file, so make sure its contents are universally applicable to all profiles you intend to define. 

You can add other keys besides `auto` to have custom shell "profiles", which is useful if you need to change `$PATH` (for various cross-compiler environments, for example), or you want a fancy `$PS1` for different `tmux`/`screen` sessions. 

To specify which profiles to load, simply name them as arguments at invocation, e.g, `gosh arduino` will load the files listed under the `arduino` key defined in `config.yml`, and found in subdirectory `~/.config/gosh/arduino`. (Remember, it also always imports first the files defined under `auto` and found in `~/.config/gosh/auto`.)

Also in `config.yml`, there are options for specifying which shell to launch (`/bin/bash`, `/bin/zsh`, etc.) along with their associated startup flags.

### Quickstart

You simply call `gosh [profile]` from your existing shell to start a new session (see [Usage](https://github.com/ardnew/gosh/#Usage) above for info about profiles).

> If you're ***hardcore*** like me, you can also replace your login shell (e.g., `/bin/bash` in `/etc/passwd`) with `/path/to/gosh` to let it always manage your shell.

Just to get up and running, I recommend using the [demo included with this repo](https://github.com/ardnew/gosh/tree/master/config/). Installation is easy:

1. Install package: `go get -v github.com/ardnew/gosh/cmd/gosh`

2. Copy the contents of [$GOPATH/src/github.com/ardnew/gosh/config/](https://github.com/ardnew/gosh/tree/master/config/) into `~/.config/gosh`.

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

## 2. [`goshfun`](https://github.com/ardnew/gosh/tree/master/cmd/goshfun) 

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
|`-f`|`string`|invoke function with given name|

### Limitations

Of course, not all library subroutines are supported. Currently, this means only functions are supported (no methods, i.e., anything with a receiver). Also, only functions with the following primitive argument and return types are supported:

- `rune`, `string`
- `error`
- `bool` 
- `int`, `int8`, `int16`, `int32`, `int64`
- `byte`, `uint`, `uint8`, `uint16`, `uint32`, `uint64`
- `uintptr`
- `float32`, `float64`
- `complex64`, `complex128`

Also, the following compositions are supported on any individual named argument or named/unnamed return variable:

- Pointer `*` to primitive 
- Slice/array `[]` of: primitive or pointer to primitive
- Variable list `...` of: primitive or pointer to primitive

With these limitations, the following functions are automatically included based on the default package selections (`strings`, `math`, and `path/filepath`), and have the indicated shell command prototype/signature. Many more functions from the Go standard library are supported, but must be explicitly requested via the `-pkg` flag to `goshfun`.

```
package path/filepath:
        Abs: path -> string error
        Base: path -> string
        Clean: path -> string
        Dir: path -> string
        EvalSymlinks: path -> string error
        Ext: path -> string
        FromSlash: path -> string
        Glob: pattern -> ...matches err
        HasPrefix: p prefix -> bool
        IsAbs: path -> bool
        Join: ...elem -> string
        Match: pattern name -> matched err
        Rel: basepath targpath -> string error
        Split: path -> dir file
        SplitList: path -> ...string
        ToSlash: path -> string
        VolumeName: path -> string
package strings:
        Compare: a b -> int
        Contains: s substr -> bool
        ContainsAny: s chars -> bool
        ContainsRune: s r -> bool
        Count: s substr -> int
        EqualFold: s t -> bool
        Fields: s -> ...string
        HasPrefix: s prefix -> bool
        HasSuffix: s suffix -> bool
        Index: s substr -> int
        IndexAny: s chars -> int
        IndexByte: s c -> int
        IndexRune: s r -> int
        Join: ...elems sep -> string
        LastIndex: s substr -> int
        LastIndexAny: s chars -> int
        LastIndexByte: s c -> int
        Repeat: s count -> string
        Replace: s old new n -> string
        ReplaceAll: s old new -> string
        Split: s sep -> ...string
        SplitAfter: s sep -> ...string
        SplitAfterN: s sep n -> ...string
        SplitN: s sep n -> ...string
        Title: s -> string
        ToLower: s -> string
        ToTitle: s -> string
        ToUpper: s -> string
        ToValidUTF8: s replacement -> string
        Trim: s cutset -> string
        TrimLeft: s cutset -> string
        TrimPrefix: s prefix -> string
        TrimRight: s cutset -> string
        TrimSpace: s -> string
        TrimSuffix: s suffix -> string
package math:
        Abs: x -> float64
        Acos: x -> float64
        Acosh: x -> float64
        Asin: x -> float64
        Asinh: x -> float64
        Atan: x -> float64
        Atan2: y x -> float64
        Atanh: x -> float64
        Cbrt: x -> float64
        Ceil: x -> float64
        Copysign: x y -> float64
        Cos: x -> float64
        Cosh: x -> float64
        Dim: x y -> float64
        Erf: x -> float64
        Erfc: x -> float64
        Erfcinv: x -> float64
        Erfinv: x -> float64
        Exp: x -> float64
        Exp2: x -> float64
        Expm1: x -> float64
        FMA: x y z -> float64
        Float32bits: f -> uint32
        Float32frombits: b -> float32
        Float64bits: f -> uint64
        Float64frombits: b -> float64
        Floor: x -> float64
        Frexp: f -> frac exp
        Gamma: x -> float64
        Hypot: p q -> float64
        Ilogb: x -> int
        Inf: sign -> float64
        IsInf: f sign -> bool
        IsNaN: f -> is
        J0: x -> float64
        J1: x -> float64
        Jn: n x -> float64
        Ldexp: frac exp -> float64
        Lgamma: x -> lgamma sign
        Log: x -> float64
        Log10: x -> float64
        Log1p: x -> float64
        Log2: x -> float64
        Logb: x -> float64
        Max: x y -> float64
        Min: x y -> float64
        Mod: x y -> float64
        Modf: f -> int frac
        NaN: -> float64
        Nextafter: x y -> r
        Nextafter32: x y -> r
        Pow: x y -> float64
        Pow10: n -> float64
        Remainder: x y -> float64
        Round: x -> float64
        RoundToEven: x -> float64
        Signbit: x -> bool
        Sin: x -> float64
        Sincos: x -> sin cos
        Sinh: x -> float64
        Sqrt: x -> float64
        Tan: x -> float64
        Tanh: x -> float64
        Trunc: x -> float64
        Y0: x -> float64
        Y1: x -> float64
        Yn: n x -> float64
```
