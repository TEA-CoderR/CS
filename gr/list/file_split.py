import socket
import struct

def ip_to_hex(ip):
    """将IP地址转换为32位十六进制值（网络字节序）"""
    try:
        packed_ip = socket.inet_aton(ip)
        return f"0x{struct.unpack('!I', packed_ip)[0]:08X}"
    except OSError:
        return None

# 输入和输出文件名
input_filename = "minerstat-mining-pools-whitelist.txt"  # 替换为您的输入文件名
ip_list_file = "ip_list.txt"
domain_struct_file = "domain_struct.txt"
ip_struct_file = "ip_struct.txt"
error_log_file = "errors.log"

error_count = 0
processed_count = 0

with open(input_filename, 'r') as infile, \
     open(ip_list_file, 'w') as ip_out, \
     open(domain_struct_file, 'w') as domain_out, \
     open(ip_struct_file, 'w') as ip_struct_out, \
     open(error_log_file, 'w') as error_out:

    for line_number, line in enumerate(infile, 1):
        # 过滤注释行和空行
        stripped_line = line.strip()
        if not stripped_line or stripped_line.startswith('#'):
            continue
            
        parts = stripped_line.split()
        if len(parts) < 2:
            error_out.write(f"第{line_number}行: 格式错误 - 需要至少两个部分: {stripped_line}\n")
            error_count += 1
            continue
            
        ip = parts[0]
        domain = parts[1]
        
        # 验证IP地址格式
        hex_ip = ip_to_hex(ip)
        if hex_ip is None:
            error_out.write(f"第{line_number}行: 无效的IP地址 '{ip}' - 跳过此行: {stripped_line}\n")
            error_count += 1
            continue
        
        # 生成IP列表文件 (xxx.xxx.xxx.xxx/32)
        ip_out.write(f"{ip}/32\n")
        
        # 生成域名结构体文件
        domain_out.write(
            f'{{ "{domain}",          "Mining",        '
            f'NDPI_PROTOCOL_MINING, CUSTOM_CATEGORY_MINING, '
            f'NDPI_PROTOCOL_UNSAFE, NDPI_PROTOCOL_DEFAULT_LEVEL }},\n'
        )
        
        # 生成IP结构体文件（含注释）
        ip_struct_out.write(
            f"{{ {hex_ip}, 32, NDPI_PROTOCOL_MINING }}, // {ip}/32 {domain}\n"
        )
        
        processed_count += 1

print(f"文件处理完成！共处理 {processed_count} 行有效数据")
if error_count > 0:
    print(f"发现 {error_count} 个错误 - 详细信息请查看 {error_log_file}")
print(f"1. IP列表文件: {ip_list_file}")
print(f"2. 域名结构体文件: {domain_struct_file}")
print(f"3. IP结构体文件: {ip_struct_file}")