#!/bin/bash
#ToDo Works great when declared and called as a function.  Fails to find most of the devices when called as a script.

TheBlackScorme() {
    local use_dc3dd=false
    local log_dir=""
    local WhatIf=false
    # Get the boot device
    local boot_device=$(df / | tail -1 | awk '{print $1}')
    # Extract the base device name (e.g., /dev/sda from /dev/sda1)
    local base_boot_device=$(echo $boot_device | sed 's/[0-9]*$//')
    # Get all devices
    local all_devices=($(lsblk -nd -o NAME))
    # Create an array excluding the boot device and its partitions
    local filtered_devices=()
    for device in "${all_devices[@]}"; do
        if [[ "/dev/$device" != "$boot_device" && "/dev/$device" != "$base_boot_device"* ]]; then
            filtered_devices+=("/dev/$device")
        fi
    done
    echo "The boot device is $boot"
    echo "The non-boot devices are $filtered_devices"

    while [[ "$1" != "" ]]; do
        case $1 in
            --dc3dd | -3 ) use_dc3dd=true ;;
            --log | -l ) shift; log_dir=$1 ;;
            --whatif | -w ) WhatIf=true ;;
            * ) echo "Invalid option: %s\n" "$1"; return 1 ;;
        esac
        shift
    done

    if $WhatIf; then
        echo "WhatIf mode enabled"  # Debug statement
        for device in $filtered_devices; do
            echo "Processing device: $device"  # Debug statement
            if $use_dc3dd; then
                if [[ -n $log_dir ]]; then
                    echo "Device $device will be wiped with dc3dd, and logged to $log_dir"
                else
                    echo "Device $device will be wiped with dc3dd, and no logs will be created."
                fi
            else
                if [[ -n $log_dir ]]; then
                    echo "Device $device will be wiped with dd, and logged to $log_dir"
                else
                    echo "Device $device will be wiped with dd, and no logs will be created."
                fi
            fi
        done
        return 0
    fi

    if [[ -n $log_dir ]]; then
        mkdir -p $log_dir
        if [[ $? -ne 0 ]]; then
            echo "Failed to create log directory %s\n" "$log_dir"
            return 1
        fi
    fi

    for device in $filtered_devices; do
        echo "Processing device: $device" 
        if $use_dc3dd; then
            if [[ -n $log_dir ]]; then
                dc3dd hwipe=$device hash=sha256 log=${log_dir}/dc3dd${device}.log hashlog=${log_dir}/hash${device}.log
            else
                dc3dd hwipe=$device hash=sha256
            fi
        else
            if [[ -n $log_dir ]]; then
                dd if=/dev/zero of=$device bs=1M status=progress 2>&1 | tee -a ${log_dir}/dd${device}.log
                sha256sum $device | tee -a ${log_dir}/hash${device}.log
            else
                dd if=/dev/zero of=$device bs=1M status=progress
                sha256sum $device
            fi
        fi
    done
}

#Leave next line commented to make script just declare the function. Uncomment to make script execute the function
#TheBlackScorme "$@"