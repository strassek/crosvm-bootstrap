FROM debian:buster

RUN apt-get update
RUN apt-get upgrade
RUN mkdir -p /app/{images}

WORKDIR /app/
USER root
RUN echo "PWD:" $PWD
ENTRYPOINT [ "/bin/bash", "/app//crosvm/exec/scripts/start.sh" ]
