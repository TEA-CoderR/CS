typedef struct {
  u_int32_t network;
  u_int8_t cidr;
  u_int16_t value;
} ndpi_network;

static ndpi_network ndpi_protocol_mining_protocol_list[] = {
  { 0x681A04C0, 32, NDPI_PROTOCOL_MINING }, // 104.26.4.192/32 2miners.com
  { 0x5FD9C5B4, 32, NDPI_PROTOCOL_MINING }, // 95.217.197.180/32 51pool.online
  { 0xA2138B78, 32, NDPI_PROTOCOL_MINING }, // 162.19.139.120/32 ae.2miners.com
  { 0x2CD52E95, 32, NDPI_PROTOCOL_MINING }, // 44.213.46.149/32 aeon.minercountry.com
  { 0xBCA518D1, 32, NDPI_PROTOCOL_MINING } // 188.165.24.209/32 aergo.eu.mine.zpool.ca
};