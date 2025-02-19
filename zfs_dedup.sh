#!/bin/bash
#
# systeembeheerder, 2024-08-16
#     2025-03-19 add support for multiple dedup vdevs in a pool    
#
# CheckMK local plugin to check disk usage on the dedup disks per pool
#
#

# Function to convert bytes to human-readable format
bytes_to_human_readable() {
    local bytes="$1"
    local units=("B" "KiB" "MiB" "GiB" "TiB" "PiB")
    local i=0
    while [ "$bytes" -ge 1024 ] && [ "$i" -lt "${#units[@]}" ]; do
        bytes=$((bytes / 1024))
        ((i++))
    done
    echo "${bytes} ${units[$i]}"
}

# Function to calculate dedup usage percentage
calculate_dedup_percentage() {
    local pool="$1"

    # Extract dedup mirrors and sum SIZE + ALLOC
    read SUM_SIZE SUM_ALLOC <<< $(zpool list -vp "$pool" | awk '
        /dedup/,0 { if (/^ *mirror-/) { size+=$2; alloc+=$3 } }
        END {print size, alloc}'
    )

    # Avoid division by zero
    if [ "$SUM_SIZE" -eq 0 ]; then
        echo "3 \"ZFS dedup disk pool ${pool}\" fs_used_percent=0;80;90|fs_used=0;;;0;0 No dedup storage available"
        return
    fi

    # Calculate deduplication size percentage
    dedup_percentage=$(awk -v used="$SUM_ALLOC" -v total="$SUM_SIZE" 'BEGIN { printf "%.2f", (used / total) * 100 }')

    # Convert dedup size and disk size to human-readable format
    human_dedup_size=$(bytes_to_human_readable "$SUM_ALLOC")
    human_dedup_disk_size=$(bytes_to_human_readable "$SUM_SIZE")

    echo "P \"ZFS dedup disk pool ${pool}\" fs_used_percent=${dedup_percentage};80;90|fs_used=${SUM_ALLOC};;;0;${SUM_SIZE} Used: ${dedup_percentage}% - $human_dedup_size of $human_dedup_disk_size"
}

# Check if zfs is available
if ! command -v zfs &>/dev/null; then
    exit 0
fi

# Get the list of pools with deduplication enabled
pools_with_dedup=$(zfs get -H dedup | awk '$3 == "on" {print $1}' | cut -d'/' -f1 | sort | uniq)

# Iterate over each pool and calculate the deduplication size percentage
for pool in $pools_with_dedup; do
    calculate_dedup_percentage "$pool"
done
