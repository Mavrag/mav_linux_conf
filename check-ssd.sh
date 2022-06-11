#!/bin/bash
#
# This script scans for SSD disks in the system
# and it checks them for media wearout status.
#
# Description and script updates can be found at:
#       http://kb.virtuozzo.com/122650
#
# Sample output:
#       # ./ssd-health-check.sh
#       direct,sda -- health 95
#       megaraid,9 -- health 100
#       cciss,3 -- health 100
#       aacraid,0,0,3 -- health 80
#
# If the last number after "health" is close to 1
# then this SSD needs replacement. Instructions
# can be found at:
#       http://kb.virtuozzo.com/123227
#
# Note:
#       AACRAID (served by 'aacraid' module)
#       needs newer 'smartctl' version.
#       Instructions for building it are in:
#               http://kb.virtuozzo.com/122650
#
disk_sign="User Capacity"
msg_wearout="Media_Wearout_Indicator|Remaining_Lifetime_Perc|Wear_Leveling_Count|Percent_Lifetime_Remain|SSD_Life_Left"
msg_endurance="SS Media used endurance indicator"
#
function check_smart() {
        local name=$1 dev=$2 smart port
        shift; shift
        if [ -z "$1" ]; then
                smart=$(smartctl -a "$dev" 2>&1)
        else for port in "$@"; do
                smart=$(smartctl -a "$dev" -d "$port" 2>&1)
                if egrep -q "^$disk_sign" <<< "$smart"; then break; fi
        done; fi
        if ! egrep -q "^$disk_sign" <<< "$smart"; then return; fi
        dev=$(awk -v mw="$msg_wearout" -v me="$msg_endurance" '
                ($1==202&&$2=="Unknown_SSD_Attribute") ||
                $0~mw{w=int(sprintf("1%03s",$4))-1000}
                $0~me{match($0,/ ([0-9]+)%/,a);w=100-a[1]}
                END{print w}' <<<"$smart")
        if [ "$dev" ]; then
                echo "$name -- health $dev$(awk -F ': +' '/Device Model:/{m=$2}/Serial Number:/{n=$2}END{if(m""n)printf" # %s %s",m,n}' <<< $"$smart")"
        fi
}
#
declare scsi
declare -i major=0
declare -A scan pssd
#
function detect_drives_modules() {
        local sdX module device
        for sdX in /sys/block/sd*; do
                module=$(readlink $sdX/device/../../../driver/module)
                module=${module##*/}
                device=${sdX##*/}
                case "$module" in
                megaraid_sas|hpsa)
                        scan["$module"]="${scan["$module"]} $device";;
                aacraid)
                        major=6
                        pssd["$module"]="${pssd["$module"]} $device";;
                #ahci|ata_piix|usb_storage|"")
                *)      scsi="$scsi $device";;
                esac
        done
        major=$(($(smartctl --version | awk -F '[ .]+' '{print $2; exit}')-major))
        [ $major -ge 0 ] ||\
                echo "Some RAID needs newer 'smartctl' version. Check http://kb.odin.com/122650 for details." >&2
}
#
function scan_directly_attached() {
        local dev
        for dev in $scsi; do check_smart "direct,$dev" "/dev/$dev"; done
}
function scan_disks_behind_raid() {
        local module port
        local -a disks
        for module in ${!scan[@]}; do case "$module" in
        megaraid_sas)
                disks=(${scan["$module"]})
                for port in {0..63}; do
                        check_smart "megaraid,$port" "/dev/${disks[0]}" "sat+megaraid,$port" "megaraid,$port"
                done;;
        hpsa)
                disks=(${scan["$module"]})
                for port in {0..63}; do
                        check_smart "cciss,$port" "/dev/${disks[0]}" "cciss,$port"
                done;;
        esac; done
}
function scan_proc_scsi_sg_devices() {
        local module
        local -a dev
        for module in ${!pssd[@]}; do case "$module" in
        aacraid)
                [ $major -ge 0 ] || {
                        echo "Skipping '$module' due to old 'smartctl'." >&2
                        continue
                }
                while read -a dev; do if [ "${dev[4]}" = 0 ]; then
                        check_smart "aacraid,${dev[0]},${dev[3]},${dev[2]}" /dev/null "aacraid,${dev[0]},${dev[3]},${dev[2]}"
                fi; done </proc/scsi/sg/devices;;
        esac; done
}
#
detect_drives_modules
scan_directly_attached
scan_disks_behind_raid
scan_proc_scsi_sg_devices
