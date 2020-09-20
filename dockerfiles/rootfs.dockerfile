FROM debian:buster-slim

RUN apt-get update
RUN apt-get install -y binfmt-support python3 debootstrap libzip-dev
RUN mkdir -p /app/{scripts,output,config}
RUN mkdir -p /app/{output,mount}

WORKDIR /app/
USER root
RUN echo "PWD:" $PWD
ENTRYPOINT [ "/bin/bash", "/app/output/scripts/main_rootfs.sh" ]
