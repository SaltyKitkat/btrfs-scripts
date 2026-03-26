#!/usr/bin/env nu
let bytes = (cat /sys/fs/btrfs/b701b97e-7ec7-46ab-9a2d-27e28f5252b0/allocation/metadata/bytes_reserved | into int);
print -n $"p=($bytes / 16 / 1024) m=(^echo $bytes | ^numfmt --to=iec-i)B";

