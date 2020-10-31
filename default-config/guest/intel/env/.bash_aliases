# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

if [ -f ~/.bash_env_settings ]; then
    . ~/.bash_env_settings
fi

export LANG=en_US.UTF-8
export COLORTERM=truecolor
export SSH_AUTH_SOCK=/run/user/${UID}/keyring/ssh
export TERM=xterm-256color

export PATH=/intel/bin:$PATH
