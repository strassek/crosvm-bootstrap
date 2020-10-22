FROM intel-vm-launch:latest

WORKDIR /app/
USER root
RUN echo "PWD:" $PWD
ENTRYPOINT [ "/bin/bash", "/scripts/stop.sh" ]
