#! /bin/bash

# package-builder.sh
# Builds all needed drivers, cros_vm and other needed packages.

export RUST_VERSION=1.45.2
export CARGO_HOME=/usr/local/cargo
export PATH=/usr/local/cargo/bin:$PATH
export RUSTFLAGS='--cfg hermetic'

cd /build

curl -LO "https://static.rust-lang.org/rustup/archive/1.22.1/x86_64-unknown-linux-gnu/rustup-init" && echo "49c96f3f74be82f4752b8bffcf81961dea5e6e94ce1ccba94435f12e871c3bdb *rustup-init" | sha256sum -c -
chmod +x rustup-init
./rustup-init -y --no-modify-path --default-toolchain $RUST_VERSION
rm rustup-init
chmod -R a+w $RUSTUP_HOME $CARGO_HOME
rustup --version
cargo --version
rustc --version
rustup default stable

# Repo initialization and cloning all needed Libraries.
ln -s /usr/bin/python3 /usr/bin/python

git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH=/build/depot_tools:$PATH

git config --global user.email "you@example.com"
git config --global user.name "Your Name"
git config --global color.ui false
repo init -u  https://github.com/kalyankondapally/manifest.git -m default.xml
repo sync

# Build libpciaccess.
cd /build/xorg-libpciaccess
./autogen.sh
make && make install
cd /build/mesa-drm

# Build drm
meson build.lib64 -Dintel=true  && ninja -C build.lib64 install
meson build.lib32 --libdir=lib -Dintel=true  && ninja -C build.lib32 install
cd /build/wayland

# Build wayland
./autogen.sh --disable-documentation
make && make install
cd /build/wayland-protocols

# Build wayland-protocols
./autogen.sh
make install
cd /build/mesa

# Build mesa
meson build.lib64 -Dplatforms=x11,wayland,surfaceless,drm -Ddri-drivers=i965 -Dgallium-drivers=iris,virgl,swrast -Dvulkan-drivers=intel -Dgallium-vdpau=false -Dgallium-va=false -Dopengl=true -Dglx=dri -Dselinux=true -Dgles1=true -Dgles2=true -Dglx-direct=true -Degl=true && ninja -C build.lib64 install
meson build.lib32 --libdir=lib -Dplatforms=x11,wayland,surfaceless,drm -Ddri-drivers=i965 -Dgallium-drivers=iris,virgl,swrast -Dvulkan-drivers=intel -Dgallium-vdpau=false -Dgallium-va=false -Dopengl=true -Dglx=dri -Dselinux=true -Dgles1=true -Dgles2=true -Dglx-direct=true -Degl=true && ninja -C build.lib32 install
cd /build/libepoxy

# Build libepoxy
meson build.lib64 && ninja -C build.lib64 install
meson build.lib32 --libdir=lib && ninja -C build.lib32 install
cd /build/minigbm

# Build minigbm
make CPPFLAGS="-DDRV_I915" DRV_I915=1 install   LIBDIR=usr/local/lib
make CPPFLAGS="-DDRV_I915" DRV_I915=1 install  LIBDIR=usr/local/lib/x86_64-linux-gnu
cp /usr/include/gbm.h /usr/local/include/
cd /build/virglrenderer

# Build virglrenderer
meson build.lib64 -Dplatforms=auto -Dminigbm_allocation=true  && ninja -C build.lib64 install
meson build.lib32 --libdir=lib -Dplatforms=auto -Dminigbm_allocation=true  && ninja -C build.lib32 install
