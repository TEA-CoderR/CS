/* extract_dns.c  */
#include <pcap.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netinet/ip.h>
#include <netinet/udp.h>
#include <arpa/inet.h>
#include <stdint.h>

#define ETHERNET_HEADER_LEN 14

void parse_dns_query(const u_char *data, int size) {
    int qname_offset = 12;

    while (qname_offset < size && data[qname_offset] != 0) {
        uint8_t len = data[qname_offset++];
        if (len == 0 || qname_offset + len > size) return;

        for (int i = 0; i < len; i++) {
            char c = data[qname_offset + i];
            if (c >= 32 && c <= 126) {
                putchar(c);
            } else {
                putchar('?');
            }
        }
        qname_offset += len;
        if (data[qname_offset] != 0)
            putchar('.');
    }
    putchar('\n');
}

void packet_handler(u_char *args, const struct pcap_pkthdr *header, const u_char *packet) {
    const struct ip *ip_hdr = (struct ip *)(packet + ETHERNET_HEADER_LEN);
    if (ip_hdr->ip_p != IPPROTO_UDP) return;

    int ip_hdr_len = ip_hdr->ip_hl * 4;
    const struct udphdr *udp_hdr = (struct udphdr *)((u_char *)ip_hdr + ip_hdr_len);

    // port 53(DNS）UDP
    if (ntohs(udp_hdr->dest) != 53) return;

    int udp_len = ntohs(udp_hdr->len);
    int dns_len = udp_len - sizeof(struct udphdr);
    const u_char *dns_data = (u_char *)udp_hdr + sizeof(struct udphdr);

    // DNS header 12 bytes
    if (dns_len < 12) return;

    // DNS_QUERY
    if ((dns_data[2] & 0x80) == 0) {
        parse_dns_query(dns_data, dns_len);
    }
}


int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <input.pcap>\n", argv[0]);
        return 1;
    }

    char errbuf[PCAP_ERRBUF_SIZE];
    pcap_t *handle = pcap_open_offline(argv[1], errbuf);
    if (!handle) {
        fprintf(stderr, "Can not open pcap file: %s\n", errbuf);
        return 1;
    }

    pcap_loop(handle, 0, packet_handler, NULL);
    pcap_close(handle);
    return 0;
}
