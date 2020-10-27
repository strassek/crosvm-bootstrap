System Dependencies	

1)Please make sure Docker is installed on the system.
For example on Ubuntu: 
sudo apt-get docker
sudo apt-get docker.io
sudo apt-get docker-compose

2)Host need's to use Wayland Compositor in case container application's need display.

3)Add user to Docker group
sudo usermod -aG docker <user account>

Launch VM

./launcher.sh $XDG_RUNTIME_DIR $WAYLAND_DISPLAY $DISPLAY

Enable GPU Pass Through

TBD

Setup Containers.

1) Once inside VM, call setup-containers.sh everytime you re-build containers/re-launch VM.
2) launch will start game-fast container.

Launch X11 applications needing Display within Container.

1) launch-x <app_name>

Launch Wayland applications needing Display within container.

1) launch <app_name>

Headless Applications

1)launch-h $<app_name>

IGT Tests
1) Run Full igt tests: igt_run full
2) Run Headless related fast feedback igt tests: igt_run fast-feedback headless
3) Run Display related fast feedback igt tests (Note: This also runs tests part of headless list): igt_run fast-feedback display 

Browse IGT Results:
1) IGT Test results are saved in launch/shared/guest/igt on host. Test results can also be found at /shared/igt/ in container.
2) Mount rootfs_guest.ext4.
3) Navigate to shared/ folder. We should have respective test result folders i.e. BAT-FAST-FEEDBACK, BAT-FULL
4) Run piglit summary html <test report name> result.json
5) Step 4 should have created <test report name> folder. It should have index.html page. Open this in your browser and view results.
