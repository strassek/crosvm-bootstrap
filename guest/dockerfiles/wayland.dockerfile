FROM intel-x11-guest:latest

ENTRYPOINT [ "/bin/bash", "/scripts/guest/main.sh" ]
