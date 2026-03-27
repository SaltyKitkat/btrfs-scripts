#!/usr/bin/env nu
let btrfs_dirs = (
    ls /sys/fs/btrfs 
    | where type == dir 
    | where { |d| ($d.name | path basename | str length) == 36 }
)

for dir in $btrfs_dirs {
    let uuid = ($dir.name | path basename)
    let size_file = $"($dir.name)/allocation/delayed_refs_rsv_size"
    let rsv_file  = $"($dir.name)/allocation/delayed_refs_rsv_reserved"

    if ($size_file | path exists) and ($rsv_file | path exists) {
        let bytes = (open $size_file | str trim | into int)
        let bytes_rsv = (open $rsv_file | str trim | into int)
        
        # 直接转化为 filesize 类型
        let r_fmt = ($bytes_rsv | into filesize)
        let m_fmt = ($bytes | into filesize)

        # 字符串插值会自动将 filesize 类型渲染为易读格式（如 1.5 KiB）
        print $"[($uuid)] p=($bytes / 16 / 1024 / 8 / 2) r=($r_fmt) m=($m_fmt)"
    }
}

