FROM debian:buster-slim

RUN apt-get update --no-install-recommends --no-install-suggests && apt-get install -y --no-install-recommends --no-install-suggests \
    autoconf \
    automake \
    curl \
    g++ \
    gcc \
    git \
    kmod \
    libcap-dev \
    libdbus-1-dev \
    libfdt-dev \
    libssl-dev \
    libtool \
    libusb-1.0-0-dev \
    make \
    nasm \
    ninja-build \
    pkg-config \
    protobuf-compiler \
    python3 \
    python3-setuptools\
    sudo \
    ssh \
    xutils-dev \
    python3-mako \
    llvm \
    cmake \
    libatomic-ops-dev \
    python3-certifi \
    gpgv2 \
    libffi-dev \
    bison \
    flex \
    cargo \
    dh-autoreconf \
    libsensors4-dev \
    libelf-dev \
    bc \
    libinput-dev \
    libudev-dev \
    libzstd-dev \
    libunwind-dev \
    python3-distutils \
    libfontenc-dev \
    wget \
    gcc-i686-linux-gnu \
    g++-i686-linux-gnu \
    libgcrypt20 \
    libgcrypt20-dev \
    libgpg-error-dev \
    libfreetype6 \
    libfreetype6-dev \
    libfontenc-dev \
    libexpat1-dev \
    xsltproc \
    libxml2-utils \
    libtool-bin \
    libxml2-dev \
    libc6-dev \
    systemd-sysv

# Export environment variables
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    RUST_VERSION=1.45.2 \
    RUSTFLAGS='--cfg hermetic'

RUN curl -LO "https://static.rust-lang.org/rustup/archive/1.22.1/x86_64-unknown-linux-gnu/rustup-init" \
    && echo "49c96f3f74be82f4752b8bffcf81961dea5e6e94ce1ccba94435f12e871c3bdb *rustup-init" | sha256sum -c - \
    && chmod +x rustup-init \
    && ./rustup-init -y --no-modify-path --default-toolchain $RUST_VERSION \
    && rm rustup-init \
    && chmod -R a+w $RUSTUP_HOME $CARGO_HOME \
    && rustup --version \
    && cargo --version \
    && rustc --version
    
RUN git clone https://github.com/mesonbuild/meson \
    && cd meson \
    && git checkout origin/0.55 \
    && ln -s $PWD/meson.py /usr/bin/meson
    
RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git \
    && cd meson \
    && export PATH=$PWD:$PATH
