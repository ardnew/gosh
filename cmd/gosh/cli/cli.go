package cli

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"sync"

	"github.com/ardnew/gosh/cmd/gosh/config"
	"github.com/ardnew/gosh/cmd/gosh/log"
	"github.com/ardnew/gosh/cmd/gosh/shell"
	"github.com/juju/errors"
)

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
		WithField("env", param.SelEnvName).
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

	defer ui.Log.Context().
		WithField("shell", ui.Config.Shell).
		Trace("running shell").
		Stop(&err)

	env := ui.readEnv()
	res := make(chan error, 1)

	go func(c *CLI, e *shell.EnvSource, r chan error) {
		err, _ := shell.Run(c.Param, c.Log, c.Config, e)
		r <- err
	}(ui, env, res)

	err = <-res // block until channel read
	return
}

func (ui *CLI) readEnv() *shell.EnvSource {

	root := filepath.Dir(ui.Param.ConfigPath)
	source := shell.EnvSource{}

	for _, env := range ui.Config.Env {
		for name, src := range env {
			if _, seen := source[name]; seen {
				ui.Log.Context().
					WithField("env", name).
					WithField("reject", "duplicate").
					Warn("skipping environment")

			} else {
				dir := filepath.Join(root, name)
				source[name] = append(source[name], ui.readEnvMod(dir, src)...)
				ui.Log.Context().
					WithField("env", name).
					WithField("size", fmt.Sprintf("%dB", len(source[name]))).
					WithField("path", dir).
					Debug("loaded environment")
			}
		}
	}

	return &source
}

func (ui *CLI) readEnvMod(path string, mod []string) []byte {

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
