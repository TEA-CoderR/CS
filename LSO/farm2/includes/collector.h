#ifndef COLLECTOR_H_
#define COLLECTOR_H_

#include <sys/select.h>

#define NTHREAD 4
#define LEN_TASK_QUEUE 8

/**
 * update fd_max nel set.
 * 
 * @param fd_max vecchio
 * @param set contiene i fd
 *	
 * @return fd_max nuovo.
 */
int update(int fd_max, fd_set *set);

/**
 * E' una funzione di eseguire un server, crea un threadpool per ricevere i 
 * risultati calolati da master_client. Poi li memoriza nel un Container.
 */
int run_collector(struct sockaddr_un *sa);

#endif
