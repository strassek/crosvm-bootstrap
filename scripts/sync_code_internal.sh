#! /bin/bash

# package-builder.sh
# Builds all needed drivers, cros_vm and other needed packages.

# Set Lib Directory based on the channel.
BASE_DIR=/opt/$LOCAL_CHANNEL/$LOCAL_BUILD_TYPE
CROSS_SETTINGS=/build/meson-cross-i686-$LOCAL_CHANNEL-$LOCAL_BUILD_TYPE.ini

# Export environment variables
export RUSTUP_HOME=/usr/local/rustup
export RUST_VERSION=1.45.2
export CARGO_HOME=/usr/local/cargo
export PATH=$CARGO_HOME:$PATH

cd /build

curl -LO "https://static.rust-lang.org/rustup/archive/1.22.1/x86_64-unknown-linux-gnu/rustup-init" && echo "49c96f3f74be82f4752b8bffcf81961dea5e6e94ce1ccba94435f12e871c3bdb *rustup-init" | sha256sum -c -
chmod +x rustup-init
./rustup-init -y --no-modify-path --default-toolchain $RUST_VERSION
rm rustup-init
chmod -R a+w $RUSTUP_HOME $CARGO_HOME
source /usr/local/cargo/env
rustup --version
cargo --version
rustc --version
rustup default stable

# Repo initialization and cloning all needed Libraries.
if [ ! -f "/usr/bin/python" ]; then
ln -s /usr/bin/python3 /usr/bin/python
fi

if [ ! -d "/build/depot_tools" ]; then
  echo "Cloning Depot Tools."
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
  git config --global color.ui false
else
  echo "Updating Depot Tools."
  cd /build/depot_tools/
  git pull
fi

export PATH=/build/depot_tools:$PATH

mkdir -p /build/stable
cd /build/stable
repo init -u  https://github.com/kalyankondapally/manifest.git -m dev.xml
repo sync

mkdir -p /build/dev
cd /build/dev
repo init -u  https://github.com/kalyankondapally/manifest.git -m dev.xml
repo sync
