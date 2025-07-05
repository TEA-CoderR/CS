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
 * E' una funzione di eseguire un server, crea un threadpool per ricevere i 
 * risultati calolati da master_client. Poi li memoriza nel un Container.
 */
int run_collector(struct sockaddr_un *sa){
	/* configure server*/
	int ssock, csock, notused;
	SYSCALL_EXIT(ssock, socket(AF_UNIX, SOCK_STREAM, 0), "socket");
	SYSCALL_EXIT(notused, bind(ssock, (struct sockaddr*)sa, sizeof(*sa)), "bind");
	SYSCALL_EXIT(notused, listen(ssock, SOMAXCONN), "listen");

	/* crea un threadpool per fare le richieste*/
	threadpool_t *pool = threadpool_create(NTHREAD, LEN_TASK_QUEUE, NULL);
	if(!pool) return -1;/* error*/

	/* crea un container per memorizzare i risulati*/
	container_t *container = container_create();
	if(!container) return -1;/* error*/

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
		struct timeval timer = {5, 0};
		int r;
		SYSCALL_EXIT(r, select(fd_max + 1, &tmpset, NULL, NULL, &timer), "select");
		if(r == 0) print_results(container);/* time out, stampa una volta risultati*/
		//printf("select successo\n");
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
						//DEBUG(1, "accepted successo\n");
						++n_conn;/* incrementa il numero di connessioni */
						FD_SET(csock, &set);
						//printf("%d registrato un client, n_conn:%ld\n", csock, n_conn);
						if(csock >fd_max) fd_max = csock;
					}
					else if(fd == request_pipe[0]){/* request di woker_addresult*/
					//printf("----------------REQUEST_PIPE---------------\n");
						int val_request;
						SYSCALL_EXIT(notused, readn(request_pipe[0], &val_request, sizeof(int)), "read");
						if(val_request == -1){/* all request finiti*/
							//if(--n_conn == 0) closeflag = 1;
							//closeflag = --n_conn + 1;
							closeflag = 1;
							printf("closeflag :%ld\n", closeflag);
						}else{
							if(!FD_ISSET(val_request, &set)){
								//printf("----------------riregistra %d------------\n", val_request);
								FD_SET(val_request, &set);/* riregistra fd*/
								if(val_request >fd_max) fd_max = val_request;
							}
						}
					}
					else{ /*Sock I/O*/
						//printf("------------%d : ----I/O---------------\n", fd);
						/* incapusula i dati*/
						addresult_t *ar = calloc(sizeof(addresult_t), 1);
						if(!ar) EXIT_F("calloc");
						ar->csock = fd;
						ar->fd1_request_pipe = request_pipe[1];
						ar->container = container;

						// pthread_t tid;
						// pthread_create(&tid, NULL, addresult, ar);

						/* create a thread deal with request*/
						if(add_task(pool, addresult, ar) == -1) break; /* On error*/
						FD_CLR(fd, &set);
						if(fd == fd_max) fd_max = update(fd_max, &set);
					}
				}
			}
		}
	}

	threadpool_close(pool);
	/* destroy threadpool*/
	if(threadpool_destroy(pool) == -1) return -1;
	/* in fine stampa i risultati*/
	print_results(container);

	container_destroy(container);

	SYSCALL_EXIT(notused, close(request_pipe[0]), "close");
	SYSCALL_EXIT(notused, close(request_pipe[1]), "close");
	/* close server*/
	SYSCALL_EXIT(notused, close(ssock), "close");

	return 0;
}