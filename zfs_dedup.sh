#!/bin/bash
#
systeembeheerder, 2024-08-16
#
# CheckMK local plugin to check disk usage on the dedup disks per pool
#
#

# Function to convert bytes to human-readable format
bytes_to_human_readable() {
    local bytes="$1"
    local units=("B" "KiB" "MiB" "GiB" "TiB")
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

    # Get the dedup data from the zpool status output
    dedup_info=$(zpool status -Dv "$pool" | awk '/dedup:/,/errors:/')

    # Extract DDT entries and sizes from the dedup info
    entries=$(echo "$dedup_info" | awk '/DDT entries/ {print $4}' | sed 's/,//g')
        size_on_disk=$(echo "$dedup_info" | awk '/size.*on disk/ {print $6}' | sed 's/B$//g')

    # Calculate the dedup size in bytes
    dedup_size_bytes=$((entries * size_on_disk))

    # Extract dedup disk names from the zpool status output
    dedup_disk=$(zpool status -Dv "$pool" | awk '/dedup/ {getline; getline; while ($0 ~ /^[[:space:]]/) {print $1; getline}}' | tail -n1)

    # Strip the gptid/ prefix from the disk name
    gptid=${dedup_disk#gptid/}

    # Get the size of each dedup disk using diskinfo
    dedup_disk_size=$(diskinfo "/dev/gptid/$gptid" 2>/dev/null | awk '{print $3}')

    # Calculate deduplication size percentage
    dedup_percentage=$(awk -v ds="$dedup_size_bytes" -v dds="$dedup_disk_size" 'BEGIN { printf "%.2f", (ds / dds) * 100 }')

    # Convert dedup size and disk size to human-readable format
    human_dedup_size=$(bytes_to_human_readable "$dedup_size_bytes")
    human_dedup_disk_size=$(bytes_to_human_readable "$dedup_disk_size")

    echo "P \"ZFS dedup disk pool ${pool}\" fs_used_percent=${dedup_percentage};80;90|fs_used=${dedup_size_bytes};;;0;${dedup_disk_size} Used: ${dedup_percentage}% - $human_dedup_size of $human_dedup_disk_size"
}

# Check if zfs and diskinfo commands are available
if ! command -v zfs &>/dev/null || ! command -v diskinfo &>/dev/null; then
    exit 0
fi

# Get the list of pools with deduplication enabled
pools_with_dedup=$(zfs get -H dedup | awk '$3 == "on" {print $1}' | cut -d'/' -f1 | sort | uniq)

# Iterate over each pool and calculate the deduplication size percentage
for pool in $pools_with_dedup; do
    calculate_dedup_percentage "$pool"
done
