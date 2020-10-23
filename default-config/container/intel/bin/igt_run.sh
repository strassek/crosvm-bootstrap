#! /bin/bash

test_name=${1}
mode=${2:-"headless"}

if [[ "$test_name" == "fast-feedback" ]]; then
	if [[ "$mode" == "display" ]] || [[ "$mode" == "headless" ]]; then
		sudo LD_LIBRARY_PATH=/opt/stable/release/x86_64/lib:/opt/stable/release/x86_64/lib/x86_64-linux-gnu IGT_CI_META_TEST=yes INTEL_SIMULATION=0 /opt/stable/release/x86_64/bin/igt_runner -o -l verbose -s --test-list /intel/igt/fast-feedback-vm-headless.testlist -b /opt/stable/release/x86_64/share/igt-gpu-tools/dg1.post_si.headless.blacklist --inactivity-timeout 90 --abort-on-monitored-error=taint --use-watchdog /opt/stable/release/x86_64/libexec/igt-gpu-tools BAT
	fi

	if [[ "$mode" == "display" ]]; then
		sudo LD_LIBRARY_PATH=/opt/stable/release/x86_64/lib:/opt/stable/release/x86_64/lib/x86_64-linux-gnu IGT_CI_META_TEST=yes INTEL_SIMULATION=0 /opt/stable/release/x86_64/bin/igt_runner -o -l verbose -s --test-list /intel/igt/fast-feedback-vm.testlist -b /opt/stable/release/x86_64/share/igt-gpu-tools/dg1.post_si.headless.blacklist --inactivity-timeout 90 --abort-on-monitored-error=taint --use-watchdog /opt/stable/release/x86_64/libexec/igt-gpu-tools BAT
	fi
else
	if [[ "$test_name" == "full" ]]; then
		sudo LD_LIBRARY_PATH=/opt/stable/release/x86_64/lib:/opt/stable/release/x86_64/lib/x86_64-linux-gnu IGT_CI_META_TEST=yes INTEL_SIMULATION=0 /opt/stable/release/x86_64/bin/igt_runner -o -l verbose -s --test-list /intel/igt/full.testlist -b /opt/stable/release/x86_64/share/igt-gpu-tools/dg1.post_si.headless.blacklist --inactivity-timeout 90 --abort-on-monitored-error=taint --use-watchdog /opt/stable/release/x86_64/libexec/igt-gpu-tools BAT	
	else
		sudo LD_LIBRARY_PATH=/opt/stable/release/x86_64/lib:/opt/stable/release/x86_64/lib/x86_64-linux-gnu /opt/stable/release/x86_64/libexec/igt-gpu-tools/$test_name
	fi
fi
