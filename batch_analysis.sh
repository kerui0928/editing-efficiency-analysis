#!/bin/bash
# Requires the following fastq file format: AMPLICON_sample-xxx.fastq.gz
# Requires AR's standard amplicon naming convention

# Organize into folders by amplicon

# 定义文件夹数组
folders=("Site1" "Site2")

# 遍历每个文件夹
for folder in "${folders[@]}"; do
    echo "Processing folder: $folder"

    # 创建文件夹（如果不存在）
    mkdir -p "$folder"

    # 将文件移动到相应文件夹
    for file in ${folder}-*; do
        mv "$file" "$folder/$(basename "$file")" 2>/dev/null || echo "No files to move for $folder"
    done

    # 进入当前文件夹
    cd "$folder" || { echo "Failed to enter folder: $folder"; exit 1; }

    # 创建 batch settings 文件
    echo -e "r1\tname" > "${folder}.txt"

    # 查找 sgRNA 和 amplicon 序列
    g=$(cat "/Users/kerui/sra/output_dir/guides+amplicons/${folder}_sgRNA.txt")
    a=$(cat "/Users/kerui/sra/output_dir/guides+amplicons/${folder}_amplicon.txt")

    # 添加 r1 和样本名到 batch settings 文件
    for sample in *.gz; do
        name="${sample%.fastq.gz}"  # 提取样本名
        echo -e "${sample}\t${name}" >> "${folder}.txt"
    done

    # 运行 CRISPRessoBatch
    docker run -v "${PWD}:/DATA" -w /DATA -i pinellolab/crispresso2 \
        CRISPRessoBatch --batch_settings "${folder}.txt" \
        -g "$g" -a "$a" -w 30 -wc -10 -q 30 -p 12

    # 返回上一级目录
    cd ..
done
