FROM intel-base-guest:latest

RUN apt-mark hold x11*:i386
RUN apt-mark hold xcb*:i386
RUN apt-mark hold *wayland*:i386
RUN apt-mark hold *gl*:i386
RUN apt-mark hold *drm*:i386
RUN apt-mark hold *gbm*:i386

ENTRYPOINT [ "/bin/bash", "/scripts/guest/main.sh" ]
