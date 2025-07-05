#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/socket.h>
#include <sys/un.h>

#include <collector.h>
#include <utils.h>
#include <threadpool.h>
#include <addresult.h>
#include <container.h>

#define NTHREAD 4
#define LEN_TASK_QUEUE 8

#define LOGNAME "log.txt"
#define wr_log 0

/**
 * update fd_max nel set.
 * 
 * @param fd_max vecchio
 * @param set contiene i fd
 *	
 * @return fd_max nuovo.
 */
int update(int fd_max, fd_set *set){
	--fd_max;
	while(!FD_ISSET(fd_max, set)) --fd_max;
	return fd_max;
}

/**
 * clean e close tutti risorse
 * 
 * @param logname puntatore FILE log
 * @param pool puntatore al thread_pool
 * @oaram container puntatore al container
 * @param exit_success flag exit
 * 
 * @return 0 On successo, return -1 On error.
 */
static int cleanall(FILE *fout_log, threadpool_t *pool, container_t *container, int exit_success){
	if(fout_log){
		if(exit_success){/* exit On success, in fine stampa nel log*/
			fprintf(fout_log, "fine> tutte le connessioni sono interrotte, collector end!\n");
		}
		fclose(fout_log);
	}
	if(pool && threadpool_destroy(pool) == -1){
		fprintf(stderr, "FATAL ERROR: threadpool_destroy in collector\n");
		return -1;
	}
	if(container){
		if(exit_success){/* exit On success, in fine stampa i risultati*/
			print_results(container);
		}
		if(container_destroy(container) == -1){
			fprintf(stderr, "FATAL ERROR: container_destroy in collector\n");
			return -1;
		}
	}
	return 0;
}

/**
 * E' una funzione di eseguire un server, crea un threadpool per ricevere i 
 * risultati calolati da master_client. Poi li memoriza nel un Container.
 */
int run_collector(struct sockaddr_un *sa){
	FILE* fout_log = NULL;
	int line = 0;
	if(wr_log){
		fout_log = fopen(LOGNAME, "w+");
		if(!fout_log){
			perror("fopen log");
			return -1;
		}
		fprintf(fout_log, "%d> collector start run!\n", line++);
	}

	/* configure server*/
	int ssock, csock, notused;
	SYSCALL_EXIT(ssock, socket(AF_UNIX, SOCK_STREAM, 0), "socket");
	SYSCALL_EXIT(notused, bind(ssock, (struct sockaddr*)sa, sizeof(*sa)), "bind");
	SYSCALL_EXIT(notused, listen(ssock, SOMAXCONN), "listen");
	if(wr_log) fprintf(fout_log, "%d> collector is listening\n", line++);

	/* crea un threadpool per fare le richieste*/
	threadpool_t *pool = threadpool_create(NTHREAD, LEN_TASK_QUEUE, NULL);
	if(!pool) return -1;/* error*/

	/* crea un container per memorizzare i risulati*/
	container_t *container = container_create();
	if(!container) {cleanall(fout_log, pool, NULL, 0); return -1;/* error*/}

	/* crea un pipe per la comunicazione tra master_collector e worker_addresult*/
	int request_pipe[2];
	SYSCALL_EXIT(notused, pipe(request_pipe), "pipe");

	/* registra i operazioni "accept" "comunicazione M-W" "I/O" sulla seletore*/
	fd_set set, tmpset;
	int fd_max = (ssock > request_pipe[0]) ? ssock : request_pipe[0];
	FD_ZERO(&set);
	FD_SET(ssock, &set);
	FD_SET(request_pipe[0], &set);

	long closeflag = 0, n_conn = 0;
	while(closeflag != 1){
		/* inizialliza tmpset*/
		tmpset = set;
		struct timeval timer = {1, 0};
		int r;
		SYSCALL_EXIT(r, select(fd_max + 1, &tmpset, NULL, NULL, &timer), "select");
		if(r == 0) print_results(container);/* time out, stampa una volta risultati*/
		else{
			/* scelta con successo*/
			for (int fd = 0; fd <= fd_max; ++fd)
			{
				if(FD_ISSET(fd, &tmpset)){
					if(fd == ssock){/* accept pronto*/
						if((csock = accept(ssock, NULL, 0)) == -1){
							if(errno = EINTR){
								if(closeflag) break;
							}
							else{
								perror("accept");
								//return -1;
							}
						}
						if(wr_log) fprintf(fout_log, "%d> ---accepted una connessione fd: %d---\n", line++, csock);
						++n_conn;/* incrementa il numero di connessioni */
						FD_SET(csock, &set);
						if(csock >fd_max) fd_max = csock;
					}
					else if(fd == request_pipe[0]){/* request di woker_addresult*/
						int val_request;
						SYSCALL_EXIT(notused, readn(request_pipe[0], &val_request, sizeof(int)), "read");
						if(val_request == -1){/* all request finiti*/
							if(wr_log) fprintf(fout_log, "%d> ---interruzione di una connessione---\n", line++);
							closeflag = --n_conn + 1;
						}else{
							if(!FD_ISSET(val_request, &set)){
								if(wr_log) fprintf(fout_log, "%d> riregistra fd: %d\n", line++, val_request);
								FD_SET(val_request, &set);/* riregistra fd*/
								if(val_request >fd_max) fd_max = val_request;
							}
						}
					}
					else{ /*Sock I/O*/
						/* incapusula i dati*/
						addresult_t *ar = calloc(sizeof(addresult_t), 1);
						if(!ar){
							cleanall(fout_log, pool, container, 0);
							return -1;
						}
						ar->csock = calloc(sizeof(int), 1);
						if(!ar->csock){
							free(ar);
							cleanall(fout_log, pool, container, 0);
							return -1;
						}
						*(ar->csock) = fd;
						ar->fd1_request_pipe = request_pipe[1];
						ar->container = container;

						if(wr_log) fprintf(fout_log, "%d> fd: %d arrivato un risultato, add un task nel pool\n", line++, fd);
						/* create a thread deal with request*/
						if(add_task(pool, addresult, ar) == -1){
							if(wr_log) fprintf(fout_log, "%d> fd: %d add task failed\n", line++, fd);
							break; /* On error*/
						}
						FD_CLR(fd, &set);
						if(fd == fd_max) fd_max = update(fd_max, &set);
					}
				}
			}
		}
	}

	/* close all resource*/
	cleanall(fout_log, pool, container, 1);

	SYSCALL_EXIT(notused, close(request_pipe[0]), "close");
	SYSCALL_EXIT(notused, close(request_pipe[1]), "close");
	/* close server*/
	SYSCALL_EXIT(notused, close(ssock), "close");
	return 0;
}
