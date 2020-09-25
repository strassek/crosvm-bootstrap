FROM intel-demos

RUN dpkg --add-architecture i386
RUN dpkg --configure -a
RUN apt-get update --no-install-recommends --no-install-suggests && apt-get install -y --no-install-recommends --no-install-suggests \
    libunwind-dev:i386 \
    libsensors4-dev:i386 \
    libelf-dev:i386 \
    libselinux1:i386 \
    libselinux1-dev:i386 \
    libudev-dev:i386 \
    libfreetype6:i386 \
    libfreetype6-dev:i386 \
    libfontenc-dev:i386 \
    libffi-dev:i386 \
    libexpat1-dev:i386 \
    libc6-dev:i386 \
    libxml2-dev:i386 \
    automake:i386 \
    autoconf:i386
