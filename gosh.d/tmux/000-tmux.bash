unbind-key C-b

bind-key C-a send-prefix
bind-key / command-prompt "split-window -h 'exec bash'"
bind-key R source-file ~/.tmux.conf \; \
	display-message "source-file done"

set-option -g prefix C-a
set-option -ga terminal-overrides ",screen-256color:Tc"

#source-file ~/.tmux/themes/tmux-themepack/powerline/default/cyan.tmuxtheme
#source-file ~/.tmux/themes/wemux.tmuxtheme

set  -g default-terminal "screen-256color"
set -sg escape-time 0

