// extract_sni.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netinet/ip.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <pcap.h>

#define ETHERNET_HEADER_LEN 14

// #define MAX_BLACKLIST 1024
// char *ip_blacklist[MAX_BLACKLIST];
// int ip_count = 0;
// char *domain_blacklist[MAX_BLACKLIST];
// int domain_count = 0;

// void load_blacklist(const char *filename, char **list, int *count) {
//     FILE *fp = fopen(filename, "r");
//     if (!fp) {
//         perror("fopen");
//         exit(1);
//     }
//     char line[256];
//     while (fgets(line, sizeof(line), fp)) {
//         line[strcspn(line, "\r\n")] = 0;
//         if (strlen(line) > 0 && *count < MAX_BLACKLIST) {
//             list[*count] = strdup(line);
//             (*count)++;
//         }
//     }
//     fclose(fp);
// }

// int is_blacklisted(const char *target, char **list, int count) {
//     for (int i = 0; i < count; i++) {
//         if (strstr(target, list[i])) return 1;
//     }
//     return 0;
// }

void parse_tls_client_hello(const u_char *payload, int len/*, const char *dst_ip*/) {
    if (len < 5 || payload[0] != 0x16 || payload[5] != 0x01) return;

    int session_id_len_offset = 43;
    if (len < session_id_len_offset + 1) return;
    int session_id_len = payload[session_id_len_offset];

    int cipher_suites_len_offset = session_id_len_offset + 1 + session_id_len;
    if (len < cipher_suites_len_offset + 2) return;
    int cipher_suites_len = (payload[cipher_suites_len_offset] << 8) | payload[cipher_suites_len_offset+1];

    int compression_methods_len_offset = cipher_suites_len_offset + 2 + cipher_suites_len;
    if (len < compression_methods_len_offset + 1) return;
    int compression_methods_len = payload[compression_methods_len_offset];

    int extensions_len_offset = compression_methods_len_offset + 1 + compression_methods_len;
    if (len < extensions_len_offset + 2) return;
    int extensions_len = (payload[extensions_len_offset] << 8) | payload[extensions_len_offset+1];
    int extensions_end = extensions_len_offset + 2 + extensions_len;

    int pos = extensions_len_offset + 2;
    while (pos + 4 < extensions_end) {
        int ext_type = (payload[pos] << 8) | payload[pos+1];
        int ext_len = (payload[pos+2] << 8) | payload[pos+3];
        pos += 4;
        if (ext_type == 0x0000) { // SNI
            if (pos + 5 > len) return;
            int server_name_len = (payload[pos+3] << 8) | payload[pos+4];
            if (pos + 5 + server_name_len > len) return;
            char sni[256] = {0};
            memcpy(sni, &payload[pos+5], server_name_len);
            // if (is_blacklisted(sni, domain_blacklist, domain_count)) {
            //     printf("[MINING] Domain blacklist match: %s\n", sni);
            // }
            printf("%s\n", sni);
            return;
        }
        pos += ext_len;
    }
}

void packet_handler(u_char *args, const struct pcap_pkthdr *header, const u_char *packet) {
    const struct ip *ip_hdr = (struct ip*)(packet + ETHERNET_HEADER_LEN);
    if (ip_hdr->ip_p != IPPROTO_TCP) return;

    // char dst_ip[INET_ADDRSTRLEN];
    // inet_ntop(AF_INET, &ip_hdr->ip_dst, dst_ip, sizeof(dst_ip));

    // if (is_blacklisted(dst_ip, ip_blacklist, ip_count)) {
    //     printf("[MINING] IP blacklist match: %s\n", dst_ip);
    //     return;
    // }

    int ip_hdr_len = ip_hdr->ip_hl * 4;
    const struct tcphdr *tcp_hdr = (struct tcphdr*)((u_char*)ip_hdr + ip_hdr_len);
    int tcp_hdr_len = tcp_hdr->th_off * 4;

    int total_hdr_len = ETHERNET_HEADER_LEN + ip_hdr_len + tcp_hdr_len;
    int payload_len = header->caplen - total_hdr_len;
    if (payload_len <= 0) return;

    const u_char *payload = packet + total_hdr_len;
    parse_tls_client_hello(payload, payload_len/*, dst_ip*/);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <file.pcap> <ip_blacklist.txt> <domain_blacklist.txt>\n", argv[0]);
        return 1;
    }

    // load_blacklist(argv[2], ip_blacklist, &ip_count);
    // load_blacklist(argv[3], domain_blacklist, &domain_count);

    char errbuf[PCAP_ERRBUF_SIZE];
    pcap_t *handle = pcap_open_offline(argv[1], errbuf);
    if (!handle) {
        fprintf(stderr, "pcap_open_offline failed: %s\n", errbuf);
        return 1;
    }

    printf("[*] Scanning for mining traffic in: %s\n", argv[1]);
    pcap_loop(handle, 0, packet_handler, NULL);
    pcap_close(handle);
    return 0;
}