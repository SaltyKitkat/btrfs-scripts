#!/usr/bin/env bash

if [ $# -lt 2 ]; then
    echo "usage: $0 -t <tree_id> <btrfs_device>"
    exit 1
fi

# 默认节点大小，单位字节（通常 16KiB）
NODE_SIZE=16384

# 允许用户指定节点大小
if [ "$1" == "-s" ]; then
    NODE_SIZE=$2
    shift 2
fi

sudo btrfs ins dump-tree --bfs --hide-names "$@" \
    | grep -E '^node|^leaf' \
    | grep 'free space' \
    | awk -v node_size=$NODE_SIZE '
/^node/ && /items [0-9]+ free space [0-9]+/ {
    # node 的统计（按 item 数量）
    for (i = 1; i <= NF; i++) {
        if ($i == "items") items = $(i+1)
        if ($i == "free" && $(i+1) == "space") free = $(i+2)
    }
    total = items + free
    if (total > 0) {
        usage = items / total
        bin = int(usage * 20)
        histogram_node[bin]++
        total_count_node++
        sum_usage_node += usage
    }
}

/^leaf/ && /items [0-9]+ free space [0-9]+/ {
    # leaf 的统计（按字节数）
    for (i = 1; i <= NF; i++) {
        if ($i == "free" && $(i+1) == "space") free = $(i+2)
    }
    used = node_size - free
    usage = used / node_size
    bin = int(usage * 20)
    histogram_leaf[bin]++
    total_count_leaf++
    sum_usage_leaf += usage
}

END {
    if (total_count_node > 0) {
        print "Node usage histogram:"
        for (i = 0; i < 20; i++) {
            count = histogram_node[i] + 0
            if (count > 0) {
                low = i * 5
                high = (i + 1) * 5
                percent = (count / total_count_node) * 100
                printf "%2d%%-%2d%%: %6.2f%%\n", low, high, percent
            }
        }
        count = histogram_node[20] + 0
        if (count > 0) {
            percent = (count / total_count_node) * 100
            printf "100%%: %6.2f%%\n", percent
        }
        avg = sum_usage_node / total_count_node * 100
        printf "on average: %.2f%%\n\n", avg
    }

    if (total_count_leaf > 0) {
        print "Leaf usage histogram:"
        for (i = 0; i < 20; i++) {
            count = histogram_leaf[i] + 0
            if (count > 0) {
                low = i * 5
                high = (i + 1) * 5
                percent = (count / total_count_leaf) * 100
                printf "%2d%%-%2d%%: %6.2f%%\n", low, high, percent
            }
        }
        count = histogram_leaf[20] + 0
        if (count > 0) {
            percent = (count / total_count_leaf) * 100
            printf "100%%: %6.2f%%\n", percent
        }
        avg = sum_usage_leaf / total_count_leaf * 100
        printf "on average: %.2f%%\n", avg
    }
}'

