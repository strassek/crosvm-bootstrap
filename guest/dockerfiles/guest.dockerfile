FROM intel-drivers-guest:latest
    
ENTRYPOINT [ "/bin/bash", "/scripts/guest/main.sh" ]
