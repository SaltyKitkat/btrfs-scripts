#! /usr/bin/env bpftrace

BEGIN {
    printf("开始监控 btrfs_commit_transaction 调用...\n");
    printf("%-20s %-16s %-8s %-12s\n", "时间", "进程名", "PID", "耗时(ms)");
}

kprobe:btrfs_commit_transaction
{
    @start[tid] = nsecs;  // 记录调用开始时间
    @pid[tid] = pid;      // 记录进程ID
    @comm[tid] = comm;    // 记录进程名
}

kretprobe:btrfs_commit_transaction
{
    $duration_ms = (nsecs - @start[tid]) / 1000000;  // 计算耗时（毫秒）

    printf("%-20s %-16s %-8d %-12llu\n", 
        strftime("%H:%M:%S", nsecs),  // 正确使用 strftime 需要两个参数
        @comm[tid], 
        @pid[tid], 
        $duration_ms);

    // 清理临时存储
    delete(@start[tid]);
    delete(@pid[tid]);
    delete(@comm[tid]);
}

END {
    printf("监控结束。\n");
}
