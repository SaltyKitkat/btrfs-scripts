#!/usr/bin/env python3

import btrfs
import sys
import heapq

if len(sys.argv) != 2:
    print("Usage: {} <mountpoint>".format(sys.argv[0]))
    sys.exit(1)


def get_least_used_block_groups(fs, top_n=10):
    """获取已用空间最少的 N 个数据块组（低内存占用版本）"""
    
    def candidate_iterator():
        """生成器：惰性地产生候选块组，避免一次性加载所有数据"""
        for chunk in fs.chunks():
            # 只关注数据块组
            if not (chunk.type & btrfs.BLOCK_GROUP_DATA):
                continue
            
            try:
                block_group = fs.block_group(chunk.vaddr, chunk.length)
                # 注意：元组第一个元素是排序键（使用率）
                # heapq.nsmallest 会自动按第一个元素排序
                if block_group.used == 0:
                    continue
                
                yield (block_group.used, block_group)
            except IndexError:
                continue
    
    # heapq.nsmallest 仅保留最小的 top_n 个元素
    # 时间复杂度: O(N log top_n)
    # 空间复杂度: O(top_n)
    top_items = heapq.nsmallest(top_n, candidate_iterator())
    
    # 转换回 (block_group, used_pct) 格式，保持接口一致
    return [(bg, used) for used, bg in top_items]

with btrfs.FileSystem(sys.argv[1]) as fs:
    print("Searching for the 10 least used DATA block groups...\n")
    
    least_used = get_least_used_block_groups(fs, top_n=10)
    
    if not least_used:
        print("No DATA block groups found.")
        sys.exit(0)
    
    # 打印表头（最后一列改为 used_space）
    print("{:>12}     {:>12} {:>12} {:>12}".format(
        "vaddr", "length", "used_pct", "used_space"))
    print("-" * 56)
    
    # 打印每个块组的信息
    for bg, used_pct in least_used:
        unit = "KiB" if bg.used < 1024*1024 else "MiB"
        size = bg.used // 1024 if bg.used < 1024*1024 else bg.used // 1024 // 1024
        print(f"{bg.vaddr:>14} {bg.length // 1024 // 1024:>10}MiB {bg.used_pct:>10}% {size:>10}{unit}")
        # print("{:>14} {:>10}MiB {:>10}% {:>10}MiB".format(
        #     bg.vaddr, 
        #     bg.length // 1024 // 1024,
        #     bg.used_pct,
        #     bg.used // 1024 // 1024
        # ))
