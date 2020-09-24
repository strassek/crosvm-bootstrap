FROM debian:buster-slim

WORKDIR /app/
USER root
RUN echo "PWD:" $PWD
ENTRYPOINT [ "/bin/bash", "/app/crosvm/exec/scripts/stop.sh" ]
