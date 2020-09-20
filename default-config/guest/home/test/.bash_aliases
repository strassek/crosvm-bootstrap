// XDG_RUNTIME_DIR
if test -z "${XDG_RUNTIME_DIR}"; then
    export XDG_RUNTIME_DIR=/tmp/${UID}-runtime-dir
    if ! test -d "${XDG_RUNTIME_DIR}"; then
        mkdir "${XDG_RUNTIME_DIR}"
        chmod 0700 "${XDG_RUNTIME_DIR}"
    fi
fi

# Export environment variables
export WLD=/opt/stable/release/x86
export WLD_64=/opt/stable/release/x86_64

export PATH=/intel/bin:$WLD_64/bin:$WLD/bin:$PATH
export LIBGL_DRIVERS_PATH=$WLD_64/lib/x86_64-linux-gnu/dri:$WLD/lib/dri
export LD_LIBRARY_PATH=$WLD_64/lib/x86_64-linux-gnu:$WLD_64/lib/x86_64-linux-gnu/dri:$WLD_64/lib:$WLD/lib:$WLD/lib/dri
export LIBVA_DRIVERS_PATH=$WLD_64/lib/x86_64-linux-gnu:$WLD/lib
export LIBVA_DRIVER_NAME=iHD
