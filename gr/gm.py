# generate_mining_pcap.py - 批量生成模拟 TLS SNI + 挖矿 JSON payload 的 pcapng 文件
from scapy.all import *
from scapy.layers.tls.all import *
from scapy.layers.tls.extensions import TLSExtServerNameIndication, ServerName
import random, os

# 矿池域名列表（可扩展）
sni_list = [
    "pool.supportxmr.com",
    "eth.2miners.com",
    "aeon.minercountry.com",
    "aikapool.com",
    "aionmine.org"
]

packets = []
src_ip_base = "192.168.0."
dst_ip = "203.0.113.10"

for i, sni_hostname in enumerate(sni_list):
    # TLS ClientHello with SNI
    tls_ext_sni = TLSExtServerNameIndication(
        server_names=[ServerName(server_name=sni_hostname.encode(), server_name_type=0)]
    )
    tls_extensions = [tls_ext_sni, TLS_Ext_SupportedVersions(versions=[0x0303])]

    client_hello = TLSClientHello(
        version="TLS_1_2",
        gmt_unix_time=0x5b5b5b5b,
        random_bytes=os.urandom(28),
        cipher_suites=[49195, 49196],
        compression_methods=[0],
        extensions=tls_extensions
    )

    record = TLSRecord(version="TLS_1_2", content_type="handshake", msg=client_hello)

    eth = Ether()
    ip = IP(src=f"{src_ip_base}{100+i}", dst=dst_ip)
    sport = random.randint(1024, 65535)
    tcp = TCP(sport=sport, dport=443, seq=1000+i*100, ack=0, flags="PA")

    pkt_tls = eth / ip / tcp / record
    packets.append(pkt_tls)

    # JSON-RPC mining payload
    json_payload = b'''{
      "id": 1,
      "method": "eth_submitLogin",
      "params": ["user", "pass"]
    }'''

    tcp_payload = TCP(sport=sport, dport=3333, seq=2000+i*100, ack=0, flags="PA")
    pkt_json = eth / ip / tcp_payload / Raw(load=json_payload)
    packets.append(pkt_json)

# 保存为 .pcapng
wrpcap("simulated_mining_multi.pcapng", packets)

print("✅ 已生成包含多个 SNI + JSON payload 的模拟挖矿流量文件：simulated_mining_multi.pcapng")
