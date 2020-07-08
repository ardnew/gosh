# gosh
#### Easily integrate Go with command-line shell environments

### wat
The [`github.com/ardnew/gosh`](https://github.com/ardnew/gosh) repo contains two primary utilities (written in pure Go) designed to improve the quality of your personal life.

[*Currently*](#future-work), these utilities, namely `gosh` and `goshfun` are intended for use as standlone executables.

## 1. [`gosh`](https://github.com/ardnew/gosh/cmd/gosh) 

#### Quickstart
> Ideally, you simply replace your login shell (e.g. `/bin/bash` in `/etc/fstab`) with `/path/to/gosh`, and then configure the gosh runtime. 
>
> Just to get up and running, I recommend using the [demo included with this repo](https://github.com/ardnew/gosh/config): 
>
>     1. Simply copy all of the "demo" `config/` contents to your local gosh runtime configuration path, typically located at `~/.config/gosh`.
>
>     2. Execute `gosh`, and you should see a familiar shell, but what you don't see is that it is being managed by a Go application! 
>
>     3. To see we are a Go sub-process, re-run with the following command, `gosh -l standard -g`, and you'll see the `gosh` runtime spewing out some debugging information regarding how the shell process was spawned. You'll see more once you close the shell (via `exit` or `^D`)
>

Anyway, keep an eye out for future documentation that will elaborate how useful the tool is in very common use cases (tmux/screen, compiler toolchain isolation, etc.)



## 2. [`goshfun`](https://github.com/ardnew/gosh/cmd/goshfun) 

#### Quickstart
> **TBD**

## Future work

1. Make [`gosh`](https://github.com/ardnew/gosh/cmd/gosh) and [`goshfun`](https://github.com/ardnew/gosh/cmd/goshfun) more library-friendly/hacker-tolerant
> **TBD**
