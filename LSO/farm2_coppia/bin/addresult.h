#ifndef ADDRESULT_H_
#define ADDRESULT_H_

#include <container.h>

typedef struct addresult_s{
	int csock;
	int fd1_request_pipe;
	container_t *container;
}addresult_t;

/**
 * e' una funzione di ricevere i risultati di calcolo e mettere nel contianer
 */
void *addresult(void *arg);

#endif