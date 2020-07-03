package shell

import (
	"fmt"
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
type EnvSource map[string][]byte

// Run executes a new shell with the given parameters and does not return until
// the shell exits or an error was encountered.
func Run(p *config.Parameters, l *log.Handler, c *config.Config, e *EnvSource) (error, error) {

	initFile, err := writeEnvToFile(p, l, c, e)
	if err != nil {
		return errors.Trace(err), nil
	}
	defer os.Remove(initFile.Name())

	env := os.Environ()
	arg := unique(append([]string{c.Shell}, unique(c.Args)...))
	arg = append(arg, "--rcfile", initFile.Name())

	l.Context().
		WithField("shell", c.Shell).
		WithField("args", fmt.Sprintf("[%s]", strings.Join(arg, ", "))).
		//WithField("env", fmt.Sprintf("[%s]", strings.Join(env, ", "))).
		WithField("dir", p.App.HomeDir()).
		WithField("stdin", os.Stdin.Name()).
		WithField("stdout", os.Stdout.Name()).
		WithField("stderr", os.Stderr.Name()).
		Debug("execute")

	shell := &Shell{Cmd: &exec.Cmd{
		Path:   c.Shell,
		Args:   arg,
		Env:    env,
		Dir:    p.App.HomeDir(),
		Stdin:  os.Stdin,
		Stdout: os.Stdout,
		Stderr: os.Stderr,
	}}

	return nil, errors.Trace(shell.Cmd.Run())
}

func writeEnvToFile(p *config.Parameters, l *log.Handler, c *config.Config, e *EnvSource) (*os.File, error) {

	var (
		env *os.File
		cnt int
		pos int64
		err error
	)

	env, err = tempFile(p.App.PackageName + "-")
	if err != nil {
		return nil, errors.Trace(err)
	}

	reqName, selName := p.App.ReqEnvName, p.SelEnvName
	reqBytes, reqFound := (*e)[reqName]
	selBytes, selFound := (*e)[selName]

	if reqFound {
		cnt, err = env.Write(reqBytes)
		if err != nil {
			return nil, errors.Trace(err)
		}

		l.Context().
			WithField("env", reqName).
			WithField("size", fmt.Sprintf("%dB", cnt)).
			WithField("path", fmt.Sprintf("⮔ %s", env.Name())).
			Debug("selected environment")
	}

	if (reqName != selName) && selFound {
		pos = int64(cnt)
		cnt, err = env.WriteAt(selBytes, pos)
		if err != nil {
			return nil, errors.Trace(err)
		}
		l.Context().
			WithField("env", selName).
			WithField("size", fmt.Sprintf("%dB", cnt)).
			WithField("path", fmt.Sprintf("⮔ %s", env.Name())).
			Debug("selected environment")
	}

	if err = env.Close(); err != nil {
		return nil, errors.Trace(err)
	}

	return env, nil
}

func tempFile(prefix string) (*os.File, error) {
	tmpDir := os.TempDir()
	src, err := ioutil.TempFile(tmpDir, prefix)
	if err != nil {
		return nil, errors.Trace(err)
	}
	return src, nil
}

func unique(ls []string) []string {
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
