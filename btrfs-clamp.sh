#! /usr/bin/env bpftrace

kprobe:need_preemptive_reclaim
{
    @space_info[tid] = arg0;
}

kretprobe:need_preemptive_reclaim
{
    // 从 map 取出并转换为 struct btrfs_space_info 指针
    $space_info = (struct btrfs_space_info *)@space_info[tid];
    
    if (retval == 1 && $space_info != 0) {
        printf("time=%s clamp=%d retval=%d\n",
               strftime("%H:%M:%S", nsecs),
               $space_info->clamp,
               retval);
    }
    
    delete(@space_info[tid]);
}

// 追踪 btrfs_preempt_reclaim_metadata_space 被调用
kprobe:btrfs_preempt_reclaim_metadata_space
{
    printf("time=%s [btrfs_preempt_reclaim] started\n", 
           strftime("%H:%M:%S", nsecs));
}

kretprobe:btrfs_preempt_reclaim_metadata_space
{
    printf("time=%s [btrfs_preempt_reclaim] finished\n", 
           strftime("%H:%M:%S", nsecs));
}
