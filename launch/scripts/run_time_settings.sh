UNAME=${1:-"test"}
CHANNEL=${2:-"stable"}
BUILD_TARGET=${3:-"release"}

if [ ! -e /home/$UNAME/ ]; then
  echo "Invalid User. Please run add_user first."
fi

cat > /home/$UNAME/.bash_env_settings <<EOF
# Export environment variables
export WLD=/opt/$CHANNEL/$BUILD_TARGET/x86
export WLD_64=/opt/$CHANNEL/$BUILD_TARGET/x86_64

export PATH=/intel/bin:$WLD_64/bin:$WLD/bin:$PATH
export LIBGL_DRIVERS_PATH=$WLD_64/lib/x86_64-linux-gnu/dri:$WLD/lib/dri
export LD_LIBRARY_PATH=$WLD_64/lib/x86_64-linux-gnu:$WLD_64/lib/x86_64-linux-gnu/dri:$WLD_64/lib:$WLD/lib:$WLD/lib/dri
export LIBVA_DRIVERS_PATH=$WLD_64/lib/x86_64-linux-gnu:$WLD/lib
export LIBVA_DRIVER_NAME=iHD
EOF
