FROM intel-wayland-guest:latest

ENTRYPOINT [ "/bin/bash", "/scripts/guest/main.sh" ]
