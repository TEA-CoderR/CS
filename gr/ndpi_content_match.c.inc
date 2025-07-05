typedef struct {
  char *string_to_match, *proto_name;
  u_int16_t protocol_id;
  ndpi_protocol_category_t protocol_category;
  ndpi_protocol_breed_t protocol_breed;
  int level; /* NDPI_PROTOCOL_DEFAULT_LEVEL (0) by default */
} ndpi_protocol_match;

static ndpi_protocol_match mining_matches[] = {
  { "2miners.com",          "Mining",        NDPI_PROTOCOL_MINING, CUSTOM_CATEGORY_MINING, NDPI_PROTOCOL_UNSAFE, NDPI_PROTOCOL_DEFAULT_LEVEL },
  { "aionmine.org",         "Mining",       NDPI_PROTOCOL_MINING, CUSTOM_CATEGORY_MINING, NDPI_PROTOCOL_UNSAFE, NDPI_PROTOCOL_DEFAULT_LEVEL },
  { "aeon.minercountry.com","Mining",    NDPI_PROTOCOL_MINING, CUSTOM_CATEGORY_MINING, NDPI_PROTOCOL_UNSAFE, NDPI_PROTOCOL_DEFAULT_LEVEL },
  { "aikapool.com",         "Mining",       NDPI_PROTOCOL_MINING, CUSTOM_CATEGORY_MINING, NDPI_PROTOCOL_UNSAFE, NDPI_PROTOCOL_DEFAULT_LEVEL },
  { "eth.f2pool.com",       "Mining",         NDPI_PROTOCOL_MINING, CUSTOM_CATEGORY_MINING, NDPI_PROTOCOL_UNSAFE, NDPI_PROTOCOL_DEFAULT_LEVEL },
  { NULL, NULL, 0, 0, 0, 0 }
};