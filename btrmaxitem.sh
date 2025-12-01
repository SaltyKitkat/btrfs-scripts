#!/usr/bin/env bash
if [ $# -lt 2 ]; then
    echo "usage: $0 -t <tree_id> <btrfs_device>"
    exit 1
fi

sudo btrfs ins dump-tree --hide-names "$@" \
    | grep itemsize \
    | awk '
function insert_top(k, s,    i,j){
    # 从尾部向前扫描，找到第一个比 s 大的位置 i
    for (i = 10; i >= 1; i--) {
        if (top_size[i] > s) break
    }
    if (i == 10) return          # 比第 10 名还小，直接丢弃
    # 把 i+1 到 10 整体后移一格，腾出 i+1 位置
    for (j = 10; j > i+1; j--) {
        top_size[j] = top_size[j-1]
        top_key[j]  = top_key[j-1]
    }
    # 插入新记录
    top_size[i+1] = s
    top_key[i+1]  = k
}

function extract_key_size(line,    p1,p2,key,size){
    p1 = index(line, "key (")
    p2 = index(line, "itemsize ")
    if (p1==0 || p2==0) return -1
    p1 += 5
    key_len = index(substr(line, p1), ")") - 1
    if (key_len < 0) return -1
    key = substr(line, p1, key_len)
    if (match(substr(line, p2), /[0-9]+/))
        size = substr(line, p2+RSTART-1, RLENGTH) + 0
    else
        return -1
    insert_top(key, size)
    return 0
}

{ extract_key_size($0) }

END {
    if (top_size[1] == "") {
        print "未找到任何有效记录。"
        exit
    }
    print "Top10 itemsize："
    for (i = 1; i <= 10; i++) {
        if (top_size[i] == "") break
        printf "%2d. size=%-10s  key=(%s)\n", i, top_size[i], top_key[i]
    }
}'

