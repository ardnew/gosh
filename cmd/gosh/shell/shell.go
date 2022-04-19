package shell

import (
	"bufio"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"os/exec"
	"strings"

	"github.com/ardnew/gosh/cmd/gosh/config"
	"github.com/ardnew/gosh/cmd/gosh/log"
	"github.com/juju/errors"
)

// Shell represents a running shell command process.
type Shell struct {
	Cmd *exec.Cmd
}

// EnvSource contains each of the loadable environments available.
type ProfileEnv map[string][]byte

// Run executes a new shell with the given parameters and does not return until
// the shell exits or an error was encountered.

func Run(p *config.Parameters, l *log.Handler, c *config.Config, s *config.Shell, e *ProfileEnv) (shellErr error, cmdErr error) {

	initFile, profiles, err := writeEnvToFile(p, l, c, e)
	if err != nil {
		return errors.Trace(err), nil
	}
	defer os.Remove(initFile)

	var env []string
	if !p.OrphanEnviron {
		env = os.Environ()
	}

	const initKey = "GOSH_INIT"
	initVal := initFile

	const profKey = "GOSH_PROFILE"
	profVal := strings.Join(profiles, ",")

	envHasProf, envHasInit := false, false
	for i, e := range env {
		v := strings.SplitN(e, "=", 2)
		if len(v) > 0 {
			switch v[0] {
			case initKey:
				// redefine the init file if it already exists in the env
				env[i] = fmt.Sprintf("%s=%s", initKey, initVal)
				envHasInit = true
			case profKey:
				if len(v) > 1 {
					// keep the profiles that were already set previously
					profVal = fmt.Sprintf("%s(%s)", profVal, v[1])
				}
				env[i] = fmt.Sprintf("%s=%s", profKey, profVal)
				envHasProf = true
			}
		}
	}

	// do not append init file if we are only generating it (it will be deleted)
	if !envHasInit && !p.GenerateInit {
		env = append(env, fmt.Sprintf("%s=%s", initKey, initVal))
	}

	if !envHasProf {
		env = append(env, fmt.Sprintf("%s=%s", profKey, profVal))
	}

	if p.GenerateInit {

		return nil, errors.Trace(copyInit(os.Stdout, env, initFile, p, c))

	} else {

		wd, wdErr := os.Getwd()
		if nil != wdErr {
			wd = p.App.HomeDir()
		}

		var arg []string
		exp := config.NewArgExpansion(initFile, wd, p.ShellArgs...)
		if p.ShellCommand == "" {
			arg = nonEmpty(exp.ExpandArgs(append([]string{s.Exec}, s.Flag.Interactive...)...)...)
		} else {
			arg = nonEmpty(exp.ExpandArgs(append([]string{s.Exec}, s.Flag.CommandLine...)...)...)
		}

		for _, pro := range p.Profiles {
			done := false
			if pd, ok := c.Profile[pro]; ok {
				switch cwd := exp.Expand(pd.Cwd); s := cwd.(type) {
				case string:
					wd, done = s, true
				}
			}
			if done {
				break
			}
		}

		l.Context().
			WithField("shell", s.Exec).
			WithField("args", fmt.Sprintf("[%s]", strings.Join(arg, ", "))).
			WithField("env", fmt.Sprintf("[%s]", strings.Join(env, ", "))).
			WithField("dir", wd).
			WithField("stdin", os.Stdin.Name()).
			WithField("stdout", os.Stdout.Name()).
			WithField("stderr", os.Stderr.Name()).
			Debug("execute")

		shell := &Shell{Cmd: &exec.Cmd{
			Path:   s.Exec,
			Args:   arg,
			Env:    env,
			Dir:    wd,
			Stdin:  os.Stdin,
			Stdout: os.Stdout,
			Stderr: os.Stderr,
		}}

		return nil, errors.Trace(shell.Cmd.Run())
	}
}

func copyInit(out io.Writer, env []string, init string, par *config.Parameters, cfg *config.Config) error {

	// open the init file for reading
	fh, err := os.Open(init)
	if nil != err {
		return errors.Trace(err)
	}
	defer fh.Close()

	// first line is always the interpreter
	bang := fmt.Sprintf("#!%s", cfg.Shell)
	_, err = fmt.Fprintln(out, bang)
	if nil == err {
		// export the environment unless orphan specified
		if !par.OrphanEnviron {
			for _, s := range env {
				v := strings.SplitN(s, "=", 2)
				if len(v) > 1 {
					s = fmt.Sprintf("%s=%q", v[0], v[1])
					_, err = fmt.Fprintln(out, "export", s)
					if nil != err {
						break
					}
				}
			}
		}
		// copy the init file contents
		scan := bufio.NewScanner(fh)
		for (nil == err) && scan.Scan() {
			s := scan.Text()
			// ignore any redundant shebangs
			if strings.TrimSpace(s) != bang {
				_, err = fmt.Fprintln(out, s)
			}
		}
		if nil == err {
			err = scan.Err()
		}
	}

	return errors.Trace(err)
}

func writeEnvToFile(p *config.Parameters, l *log.Handler, c *config.Config, e *ProfileEnv) (string, []string, error) {

	var env *os.File
	var err error

	env, err = tempFile(p.App.PackageName + "-")
	if err != nil {
		return "", nil, errors.Trace(err)
	}

	var cnt int
	var pos int64

	seen := map[string]int{}
	for i, sel := range append([]string{p.App.ReqProfileName}, p.Profiles...) {

		if _, ok := seen[sel]; ok {
			continue
		}

		seen[sel] = i
		if bytes, found := (*e)[sel]; found {
			pos += int64(cnt)
			cnt, err = env.WriteAt(bytes, pos)
			if err != nil {
				return "", nil, errors.Trace(err)
			}

			l.Context().
				WithField("profile", sel).
				WithField("env", fmt.Sprintf("[ %s ]", strings.Join(c.Profile[sel].Env, ", "))).
				WithField("size", fmt.Sprintf("%dB", cnt)).
				WithField("path", fmt.Sprintf("⮔ %s", env.Name())).
				Info("activated profile")
		}
	}

	sel := make([]string, len(seen))
	i := 0
	for s := range seen {
		sel[i] = s
		i++
	}

	if err = env.Close(); err != nil {
		return "", nil, errors.Trace(err)
	}

	return env.Name(), sel, nil
}

func tempFile(prefix string) (*os.File, error) {
	tmpDir := os.TempDir()
	src, err := ioutil.TempFile(tmpDir, prefix)
	if err != nil {
		return nil, errors.Trace(err)
	}
	return src, nil
}

func unique(ls ...string) []string {
	seen := map[string]int{}
	uniq := []string{}
	for i, a := range ls {
		if _, ok := seen[a]; !ok {
			seen[a] = i
			uniq = append(uniq, a)
		}
	}
	return uniq
}

func nonEmpty(ls ...string) []string {
	rs := make([]string, 0, len(ls))
	for _, a := range ls {
		if a != "" {
			rs = append(rs, a)
		}
	}
	return rs
}
