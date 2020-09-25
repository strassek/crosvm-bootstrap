FROM intel-base:latest

RUN apt-mark hold x11*
RUN apt-mark hold xcb*
RUN apt-mark hold *wayland*
RUN apt-mark hold *gl*
RUN apt-mark hold *drm*
RUN apt-mark hold *gbm*

ENTRYPOINT [ "/bin/bash", "/scripts/host/main.sh" ]
