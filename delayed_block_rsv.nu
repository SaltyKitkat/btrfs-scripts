#!/usr/bin/env nu
let bytes = (cat /sys/fs/btrfs/b701b97e-7ec7-46ab-9a2d-27e28f5252b0/allocation/delayed_block_rsv_size | into int);
let bytes_rsv = (cat /sys/fs/btrfs/b701b97e-7ec7-46ab-9a2d-27e28f5252b0/allocation/delayed_block_rsv_reserved  | into int);
print -n $"p=($bytes / 16 / 1024 /  2) r=(^echo $bytes_rsv | ^numfmt --to=iec-i) m=(^echo $bytes | ^numfmt --to=iec-i)B";

