# CheckMK_zfs-dedup
CheckMK Local Check to monitor the usage of dedup disks


Place script in /usr/local/lib/check_mk_agent/local/ or /usr/local/lib/check_mk_agent/local/7200/

exmple output:
```
P "ZFS dedup disk pool Vol-12TB-2x6-Mirror-1" fs_used_percent=37.82;80;90|fs_used=378257943276;;;0;1000204800000 Used: 37.82% - 352 GiB of 931 GiB
P "ZFS dedup disk pool Vol-12TB-2x6-Mirror-2" fs_used_percent=38.89;80;90|fs_used=389016923256;;;0;1000204800000 Used: 38.89% - 362 GiB of 931 GiB
P "ZFS dedup disk pool Vol-12TB-2x8-Mirror-1" fs_used_percent=1.57;80;90|fs_used=6296489796;;;0;400088371200 Used: 1.57% - 5 GiB of 372 GiB
```

