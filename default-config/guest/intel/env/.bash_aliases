# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

if [ -f ~/.bash_env_settings ]; then
    source ~/.bash_env_settings
    export PATH=$WLD_64/bin:$WLD/bin:$WLD_64/lib64:/intel/bin:/intel/bin/container:/usr/bin/:$PATH
    export LIBGL_DRIVERS_PATH=$WLD_64/lib/x86_64-linux-gnu/dri:$WLD/lib/dri:$WLD_64/lib64
    export LD_LIBRARY_PATH=$WLD_64/lib/x86_64-linux-gnu:$WLD_64/lib/x86_64-linux-gnu/dri:$WLD_64/lib64:$WLD_64/lib:$WLD/lib:$WLD/lib/dri
    export LIBVA_DRIVERS_PATH=$WLD_64/lib/x86_64-linux-gnu:$WLD/lib
    export LIBVA_DRIVER_NAME=iHD
fi

export LANG=en_US.UTF-8
export COLORTERM=truecolor
#export SSH_AUTH_SOCK=/run/user/${UID}/keyring/ssh
export TERM=xterm-256color
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
