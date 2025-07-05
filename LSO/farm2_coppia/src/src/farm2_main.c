/***********************************************************************
*** progetto LSO farm2
*** 
*** 
*** 
*** @author Yang Juhong
*** @date 01/05/2024
***********************************************************************/



#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>

#include <queue.h>

#ifndef SOCKETNAME
#define SOCKETNAME "./farm2.sck"
#endif

/** 
 *  definisce una struttura sighandler_t per memorizzare i dati a
 *  passare a thread sighandler.
 * 
 * @var set dei segnali da gestire
 * @var fd1_sig_pipe lato scrittura del pipe sig_pipe
 * @var fd1_usr1_pipe lato scrittura del pipe usr1_pipe
 * @var fd1_usr2_pipe lato scrittura del pipe usr2_pipe
 */
typedef struct{
	sigset_t *set;
	int fd1_sig_pipe;
	int fd1_usr1_pipe;
	int fd1_usr2_pipe;
}sighandler_t;

/** 
 *  definisce una struttura gestoreMaster_t per memorizzare i dati a
 *  passare a thread gestoreMaster.
 * 
 * @var closeflag puntatore a closeflag
 * @var fd0_sig_pipe lato lettura del pipe sig_pipe
 * @var fd0_request_pipe lato lettura del pipe request_pipe
 * @var fd0_usr1_pipe lato lettura del pipe usr1_pipe
 * @var fd0_usr2_pipe lato lettura del pipe usr2_pipe
 */
typedef struct{
	int *closeflag;
	int fd0_sig_pipe;
	int fd0_request_pipe;
	int fd0_usr1_pipe;
	int fd0_usr2_pipe;
}gestoreMaster_t;

/** 
 *  inizialliza sockaddr
 * 
 * @param sa socket address
 */
static void inizialliza(struct sockaddr_un *sa);

/** 
 *  inizialliza sigset e maschera i segnali da gestire, ignora SIGPIPE
 * 
 * @param mask sigset agli signali da mascherare
 * @param oldmask sigset vecchio
 * @param s puntatore alla una struttura di sigaction
 */
static void mascheraSig(sigset_t *mask, sigset_t *oldmask, struct sigaction *s);

static void gestoreMaster(void *arg){
	int *closeflag = ((gestoreMaster_t*)arg)->closeflag;
	int fd0_sig_pipe = ((gestoreMaster_t*)arg)->fd0_sig_pipe;
	int fd0_request_pipe = ((gestoreMaster_t*)arg)->fd0_request_pipe;
	int fd0_usr1_pipe = ((gestoreMaster_t*)arg)->fd0_usr1_pipe;
	int fd0_usr2_pipe = ((gestoreMaster_t*)arg)->fd0_usr2_pipe;

	fd_set set, tmpset;
	int notused, n, nread;
	int fd_max = (fd0_sig_pipe > fd0_request_pipe) ? fd0_sig_pipe : fd0_request_pipe;
	if(fd0_usr1_pipe > fd_max) fd_max = fd0_usr1_pipe;
	if(fd0_usr2_pipe > fd_max) fd_max = fd0_usr2_pipe;
	
	/* registra i operazioni "terminazione" "incrementa thread" "decrementa thread" "request"*/
	FD_ZERO(&set);
	FD_SET(fd0_sig_pipe, &set);
	FD_SET(fd0_request_pipe, &set);
	FD_SET(fd0_usr1_pipe, &set);
	FD_SET(fd0_usr2_pipe, &set);
	while(!(*closeflag)){
		/* inizialliza tmpset*/
		tmpset = set;
		SYSCALL_EXIT(notused, select(fd_max + 1, &tmpset, NULL, NULL, NULL), "select");
		/* scelta con successo*/
		for (int fd = 0; fd <= fd_max; ++fd)
		{
			if(FD_ISSET(fd, &tmpset)){
				if(fd == fd0_sig_pipe){/* il signale del terminazione arrivato*/
					SYSCALL_EXIT(notused, close(fd0_sig_pipe), "close");
					*closeflag = 1;
					break;
				}
				else if(fd == fd0_usr1_pipe){/* incrementa di una unità il numero di thread Worker nel pool*/
					SYSCALL_EXIT(nread, read(fd0_usr1_pipe, &n, sizeof(int)), "read");


				}
				else if(fd == fd0_usr2_pipe){/* decrementa di una unità il numero di thread Worker nel pool*/
					SYSCALL_EXIT(nread, read(fd0_usr2_pipe, &n, sizeof(int)), "read");

				}
				else{/* e' il messaggio del thread worker*/
					//da implementare, define una struttura msg_mw, read it and registra
					//su seletor, e mette libero il thread worker

				}
			}
		}
	}
}

static void sighandler(void *arg){
	sigset_t *set = ((sighandler_t*)arg)->set;
	int fd1_sig_pipe = ((sighandler_t*)arg)->fd1_sig_pipe;
	int fd1_usr1_pipe = ((sighandler_t*)arg)->fd1_usr1_pipe;
	int fd1_usr2_pipe = ((sighandler_t*)arg)->fd1_usr2_pipe;
	int n = 1, notused;

	for(;;){
		int sig;
		int r = sigwait(set, &sig);
		if(r != 0){// caso error
			errno = r;
			perror("sigwait");
			return NULL;
		}
		// ricevuto signal
		switch(sig){
		case SIGUSR1:{
			SYSCALL_EXIT(notused, write(fd1_usr1_pipe, &n, sizeof(int)), "write");
			break;
		}
		case SIGUSR12:{
			SYSCALL_EXIT(notused, write(fd1_usr2_pipe, &n, sizeof(int)), "write");
			break;
		}
		case SIGINT:
		case SIGQUIT:
		case SIGTERM:
		case SIGHUP:
			/**
			 *  notifica fd0_sig_pipe quella gia' registato sulla seletore main, per 
			 * 	terminare il server
			 */
		    SYSCALL_EXIT(notused, close(fd1_sig_pipe), "close");
		    return NULL;
		default:;
		}
	}
    return NULL;
}

int notused;
int main(int argc, char const *argv[])
{
	if(argc < 2) EXIT_F("EINVAL");
	/* define e maschera i signali*/
	sigset_t mask, oldmask;
	struct sigaction s;
	mascheraIgnoraSig(&mask, &oldmask, &s);
	/* define e inizialliza socket*/
	int ssock, csock;
	struct sockaddr_un sa;
	cleansock();
	atexit(cleansock);
	inizialliza(&sa);

	/* fork a process client*/
	int pid;
	SYSCALL_EXIT(pid, fork(), "fork");
	if(pid == 0){// processo server Collector
		/* configure server*/
		SYSCALL_EXIT(ssock, socket(AF_UNIX, SOCK_STREAM, 0), "socket");
		SYSCALL_EXIT(notused, bind(ssock, (struct sockaddr*)&sa, sizeof(sa)), "bind");
		SYSCALL_EXIT(notused, listen(ssock, SOMAXCONN), "listen");

		/* runCollector, registra i operazioni "accept" "I/O" sulla seletore*/
		fd_set set, tmpset;
		int fd_max = 0, closeflag = 0;
		if(ssock > fd_max) fd_max = ssock;
		FD_ZERO(&set);
		FD_SET(ssock, &set);
		while(!closeflag){
			/* inizialliza tmpset*/
			tmpset = set;
			int r;
			SYSCALL_EXIT(r, select(fd_max + 1, &tmpset, NULL, NULL, NULL), "select");
			if(r == 0) stampa_risultati();

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
						FD_SET(csock, &set);
						if(csock >fd_max) fd_max = csock;
					}
					else{ /*Sock I/O*/
						/* create a thread deal with request*/
						if(spawn_thread(pool, t, fd) == -1) break;
					}
				}
			}
		}
		
	}
	else{// processo client MasterWorker
		
		//runCollector, define una struttura info_file per memorrizare i risultati.
		Queue_t *coda_task;

		define pool;

		/** 
		 * usa 4 pipe senza nome, registra su seletor, sig_pipe per la terminazione 
		 * del MasterWorker, request_pipe per la comunicazione tra thread Master e 
		 * thread Worker, usr1_pipe per notifica thread gestoreMaster incrementa un thread
		 * nel pool, usr2_pipe invece, decrementa uno.
		 */
		int sig_pipe[2], request_pipe[2], usr1_pipe[2], usr2_pipe[2];
		SYSCALL_EXIT(notused, pipe(sig_pipe), "pipe");
		SYSCALL_EXIT(notused, pipe(request_pipe), "pipe");
		SYSCALL_EXIT(notused, pipe(usr1_pipe), "pipe");
		SYSCALL_EXIT(notused, pipe(usr2_pipe), "pipe");

		run sighandler;/* spawn un thread sigHandler*/

		run gestoreMaster;

		crea workers;

		run Master;		

		waitpid;
	}
	return 0;
}

/** 
 *  inizialliza sockaddr
 * 
 * @param sa socket address
 */
static void inizialliza(struct sockaddr_un *sa){
	memset(sa, '0' ,sizeof(struct sockaddr_un));
	strncpy(sa->sun_path, SOCKETNAME, strlen(SOCKETNAME) + 1);
	sa->sun_family = AF_UNIX;
}

/** 
 *  inizialliza sigset e maschera i segnali da gestire, ignora SIGPIPE
 * 
 * @param mask sigset agli signali da mascherare
 * @param oldmask sigset vecchio
 * @param s puntatore alla una struttura di sigaction
 */
static void mascheraIgnoraSig(sigset_t *mask, sigset_t *oldmask, struct sigaction *s){
    sigemptyset(mask);
    sigaddset(mask, SIGINT);
    sigaddset(mask, SIGQUIT);
    sigaddset(mask, SIGTERM);
    sigaddset(mask, SIGHUP);
    sigaddset(mask, SIGUSR1);
    sigaddset(mask, SIGUSR2);
    /* maschera tali segnali da gestire*/
    SYSCALL_EXIT(notused, pthread_sigmask(SIG_BLOCK, mask, oldmask), "pthread_sigmask");

    /* il segnale SIGPIPE deve essere ignorato*/
    memset(s, '0' ,sizeof(struct sigaction));
    s.sa_handler = SIG_IGN;
    SYSCALL_EXIT(notused, sigaction(SIGPIPE, s, NULL), "sigaction");
}