#ifndef CONNECT_H_
#define CONNECT_H_

#ifndef MAX_FILENAME_LEN
#define MAX_FILENAME_LEN 255
#endif

typedef struct msg_s{
	long result;
	char *filename;
}msg_t;

#endif
