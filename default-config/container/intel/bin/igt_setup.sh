#! /bin/bash

mode=${1:-"--headless"}

LOCAL_LIST_NAME='fast-feedback-vm.txt'
if [[ "$mode" == "--headless" ]]; then
	LOCAL_LIST_NAME='fast-feedback-vm-headless.txt'
fi

sudo LD_LIBRARY_PATH=/opt/stable/release/x86_64/lib:/opt/stable/release/x86_64/lib/x86_64-linux-gnu IGT_CI_META_TEST=yes INTEL_SIMULATION=0 /opt/stable/release/x86_64/bin/igt_runner -o -l verbose -s --test-list /opt/stable/release/x86_64/$LOCAL_LIST_NAME -b /opt/stable/release/x86_64/share/igt-gpu-tools/dg1.post_si.headless.blacklist --inactivity-timeout 180 --abort-on-monitored-error=taint --piglit-style-dmesg --dmesg-warn-level=4 -n "FAST GAME CONTAINER" --use-watchdog /opt/stable/release/x86_64/libexec/igt-gpu-tools dg1_resume
