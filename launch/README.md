# Enable Wayland on Ubuntu
Execute below steps on Ubuntu Desktop but not via remote ssh
Open /etc/gdm3/custom.conf and ensure WaylandEnable=false is commented.
Logout and click on the gear button and select option "Ubuntu on Wayland"
once booted to desktop, make sure "echo $WAYLAND_DISPLAY" = wayland-0.

## Quickstart
1. Install all system dependencies:
```bash
./tools/install_system_dependencies.sh
```
2. Launch the vm and Guest Container:
```bash
cd build/launch
./launcher.sh
To enable GPU pass through support:
./launcher.sh --true
```
3. Once inside container you can run demo application using the launch statment such as
the following for X11:
```bash
launch-x es2gears_wayland
```
4. Re-launch Container within container: 
This is really needed only if you need to exit the container within the VM for any reason.
```bash
launch
```
5. Launch X11 applications needing Display within Container.

launch-x <app_name>

6. Launch Wayland applications needing Display within container.

launch <app_name>

7. Headless Applications

launch-h $<app_name>

8. IGT Tests
8.a) Run Full igt tests: 
```bash
igt_run full
```
8.b) Run Headless related fast feedback igt tests:
```bash
igt_run fast-feedback headless
```
8.b) Run Display related fast feedback igt tests (Note: This also runs tests part of headless list):
```bash
igt_run fast-feedback display 
```
Browse IGT Results:
1) IGT Test results are saved in launch/shared/guest/igt on host. Test results can also be found at /shared/igt/ in container.
2) Run piglit summary html <test report name> result.json
3) Step 4 should have created <test report name> folder. It should have index.html page. Open this in your browser and view results.
