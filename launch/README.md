#System Dependencies
1)Please make sure Docker is installed on the system.
For example on Ubuntu: 
sudo apt-get docker
sudo apt-get docker.io
sudo apt-get docker-compose

2)Host need's to use Wayland Compositor in case container application's need display.

3)Add user to Docker group
sudo usermod -aG docker <user account>

4)Launch VM:
./launcher.sh $XDG_RUNTIME_DIR $WAYLAND_DISPLAY $DISPLAY

5) Enable GPU Pass Through:
TBD

6) Setup Containers.
	A) Once inside VM, call setup-containers.sh everytime you re-build containers/re-launch VM.
	B) launch will start game-fast container.

7) Launch X11 applications needing Display within Container.
	launch-x <app_name>

8) Launch Wayland applications needing Display within container.
	launch <app_name>

9) Headless Applications: 
Just use application name.
$<app_name>
