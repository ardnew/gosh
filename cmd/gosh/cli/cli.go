package cli

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"sync"

	"github.com/ardnew/gosh/cmd/gosh/config"
	"github.com/ardnew/gosh/cmd/gosh/log"
	"github.com/ardnew/gosh/cmd/gosh/shell"
	"github.com/juju/errors"
)

// RestartFileBase generates the basename of the restart file for the current
// process.
var RestartFileBase = func() string {
	return fmt.Sprintf(".restart.%d", os.Getpid())
}

// CLI represents the properties of an active command-line session.
type CLI struct {
	Param  *config.Parameters
	Log    *log.Handler
	Config *config.Config
}

// Start creates a new command-line session with given parameters.
func Start(param *config.Parameters) (ui *CLI, err error) {

	ui = &CLI{
		Param: param,
		Log:   log.NewHandler(os.Stdout, param),
	}

	defer ui.Log.Context().
		WithField("configPath", param.ConfigPath).
		WithField("profiles", fmt.Sprintf("[ %s ]", strings.Join(param.Profiles, ", "))).
		Trace("initialization").
		Stop(&err)

	// assert the configuration file path's existance
	err = os.MkdirAll(filepath.Dir(param.ConfigPath), param.App.PermConfigDir)
	if err != nil {
		err = errors.Trace(err)
		return
	}

	// parse the configuration file
	ui.Config, err = config.ParseFile(param.ConfigPath)
	if err != nil {
		err = errors.Trace(err)
		return
	}

	ui.Log.Context().
		WithField("config", ui.Config.String()).
		Debug("parsed configuration")

	return
}

// CreateShell opens and attaches to a new shell as defined in the user's
// configuration file.
func (ui *CLI) CreateShell() (err error) {

	sh, ok := ui.Config.Shell[ui.Param.Shell]
	if !ok {
		err = errors.Errorf("undefined shell: %s", ui.Param.Shell)
	}

	defer ui.Log.Context().
		WithField("exec", sh.Exec).
		Trace("running shell").
		Stop(&err)

	env := ui.readProfile()
	res := make(chan error, 1)

	// controls ability to restart shell
	startShell := true

	for startShell {
		// always remove the restart file immediately
		ui.removeRestartFile()

		go func(c *CLI, e *shell.ProfileEnv, s *config.Shell, r chan error) {
			shellErr, _ := shell.Run(c.Param, c.Log, c.Config, s, e)
			r <- shellErr
		}(ui, env, &sh, res)
		err = <-res // block until channel read

		// check if a restart file exists
		var selected string
		if selected, startShell = ui.readRestartFile(); startShell {
			// scan its contents into the selected-environments parameters
			ui.Param.Profiles = ui.splitDataRestartFile(selected)
		}
	}
	return
}

func (ui *CLI) readProfile() *shell.ProfileEnv {
	root := filepath.Dir(ui.Param.ConfigPath)
	source := shell.ProfileEnv{}
	for name, pro := range ui.Config.Profile {
		if _, seen := source[name]; seen {
			ui.Log.Context().
				WithField("profile", name).
				WithField("reject", "duplicate").
				Warn("skipping profile")
		} else {
			// Insert the profile-specific env before sourcing any of its includes
			for _, e := range pro.Env {
				source[name] = append(source[name], e...)
			}
			dir := filepath.Join(root, name)
			source[name] = append(source[name], ui.readProfileMod(dir, pro.Include...)...)
			ui.Log.Context().
				WithField("profile", name).
				WithField("env", fmt.Sprintf("[ %s ]", strings.Join(pro.Env, ", "))).
				WithField("size", fmt.Sprintf("%dB", len(source[name]))).
				WithField("path", dir).
				Debug("loaded profile")
		}
	}

	return &source
}

func (ui *CLI) readProfileMod(path string, mod ...string) []byte {

	type buf []byte

	each := make([]buf, len(mod))
	work := sync.WaitGroup{}
	work.Add(len(mod))

	// spawn a goroutine to read each file in a subdirectory simultaneously, each
	// filling their own separate buffers as they go.
	for i, file := range mod {
		each[i] = buf{}
		go func(wg *sync.WaitGroup, fp string, ob *buf) {
			if bytes, err := ioutil.ReadFile(fp); err != nil {
				ui.Log.Context().WithError(errors.Trace(err)).Warn("skipping file")
			} else {
				*ob = append(*ob, bytes...)
			}
			wg.Done()
		}(&work, filepath.Join(path, file), &each[i])
	}
	work.Wait()

	// now piece each block together in the right order
	env := []byte{}
	for _, b := range each {
		env = append(env, b...)
	}
	return env
}

func (ui *CLI) splitDataRestartFile(selected string) []string {
	return strings.Fields(selected)
}

func (ui *CLI) joinDataRestartFile(selected ...string) string {
	for i, s := range selected {
		selected[i] = strings.TrimSpace(s)
	}
	return strings.Join(selected, " ")
}

func (ui *CLI) readRestartFile() (string, bool) {
	path := filepath.Join(filepath.Dir(ui.Param.ConfigPath), RestartFileBase())
	bytes, err := ioutil.ReadFile(path)
	if err != nil {
		return "", false
	}
	selected := string(bytes)
	return selected, selected != ""
}

func (ui *CLI) writeRestartFile(selected string) {
	path := filepath.Join(filepath.Dir(ui.Param.ConfigPath), RestartFileBase())
	_ = ioutil.WriteFile(path, []byte(selected), ui.Param.App.PermConfigFile)
}

func (ui *CLI) removeRestartFile() {
	path := filepath.Join(filepath.Dir(ui.Param.ConfigPath), RestartFileBase())
	_ = os.Remove(path)
}
