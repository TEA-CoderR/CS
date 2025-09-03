import sys

def compare_files(file1, file2):
    with open(file1, 'r', encoding='utf-8') as f1, open(file2, 'r', encoding='utf-8') as f2:
        lines1 = f1.readlines()
        lines2 = f2.readlines()

    max_len = max(len(lines1), len(lines2))

    for i in range(max_len):
        line1 = lines1[i].rstrip('\n') if i < len(lines1) else '<文件1无此行>'
        line2 = lines2[i].rstrip('\n') if i < len(lines2) else '<文件2无此行>'
        
        if line1 != line2:
            print(f"第 {i+1} 行不同：")
            print(f"文件1: {line1}")
            print(f"文件2: {line2}")
            print("-" * 40)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"用法: python {sys.argv[0]} 文件1 文件2")
        sys.exit(1)

    compare_files(sys.argv[1], sys.argv[2])
