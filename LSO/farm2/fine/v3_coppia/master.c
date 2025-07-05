//#define _POSIX_C_SOURCE 200112L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <pthread.h>
#include <sys/wait.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <signal.h>

#include "utils.h"
#include "master.h"
//#include "threadpool.h"
#include "countfile.h"

int getopt(int argc, char * const argv[], const char *optstring);
char *optarg;
int optind, opterr, optopt;
int usleep(suseconds_t usec);
int sigwait(const sigset_t *set, int *sig);
int kill(pid_t pid, int sig);

#ifndef NTHREAD
#define NTHREAD 4
#endif

#ifndef NSOCKET
#define NSOCKET 6
#endif

#ifndef LEN_TASK_QUEUE
#define LEN_TASK_QUEUE 8
#endif

#ifndef DELAY_MASTER
#define DELAY_MASTER 0
#endif

#ifndef MAX_FILENAME_LEN
#define MAX_FILENAME_LEN 255
#endif

#ifndef NWORKERATEXIT1
#define NWORKERATEXIT1 "nworkeratexit.txt"
#endif

/**
 * e' una funzione sig_attuatore di sig_ricevitore, dopo riceuti i segnali, fa corrisponde
 * azioni, se sono ricevuti SIGINT, SIGQUIT, SIGTERM, SIGHUP, termina la esecuzione progm,
 * se ricevuto SIGUSR1, incrementa un thread nel pool, se ricevuto
 * SIGUSR2, decrementa un thread nel pool.
 */
static void* sigmonitor(void *arg){
	threadpool_t *pool = ((sigmonitor_t*)arg)->pool;
	int fd0_sig_pipe = ((sigmonitor_t*)arg)->fd0_sig_pipe;
	int fd0_usr1_pipe = ((sigmonitor_t*)arg)->fd0_usr1_pipe;
	int fd0_usr2_pipe = ((sigmonitor_t*)arg)->fd0_usr2_pipe;

	fd_set set, tmpset;
	int n, nread, notused;
	int fd_max = (fd0_usr1_pipe > fd0_usr2_pipe) ? fd0_usr1_pipe : fd0_usr2_pipe;
	if(fd0_sig_pipe > fd_max) fd_max = fd0_sig_pipe;
	
	/* registra i operazioni "terminazione" "incrementa thread" "decrementa thread"*/
	FD_ZERO(&set);
	FD_SET(fd0_sig_pipe, &set);
	FD_SET(fd0_usr1_pipe, &set);
	FD_SET(fd0_usr2_pipe, &set);
	while(true){
		/* inizialliza tmpset*/
		tmpset = set;
		SYSCALL_EXIT(notused, select(fd_max + 1, &tmpset, NULL, NULL, NULL), "select");
		/* scelta con successo*/
		for (int fd = 0; fd <= fd_max; ++fd)
		{
			if(FD_ISSET(fd, &tmpset)){
				if(fd == fd0_sig_pipe){/* il signale del terminazione arrivato*/
					SYSCALL_EXIT(notused, close(fd0_sig_pipe), "close");

					do{
						/* print il numero di thread Worker presenti nel pool all’uscita at exit*/
						FILE* fout = fopen(NWORKERATEXIT1, "w+");
						if(!fout){
							perror("fopen nworkeratexit.txt");
							break;
						}
						fprintf(fout, "num_thread_Worker :%d\nnum_thread_alive :%d\n", pool->pool_size, pool->live_thr_num);
						fclose(fout);
					}while(0);

					/* notifica threadpool termina*/
					threadpool_close(pool);

					pthread_exit(NULL);
				}
				else if(fd == fd0_usr1_pipe){/* incrementa di una unità il numero di thread Worker nel pool*/
					SYSCALL_EXIT(nread, read(fd0_usr1_pipe, &n, sizeof(int)), "read");
					if(nread == 0){
						perror("FATAL ERROR: fd0_usr1_pipe");
						pthread_exit(NULL);
					}

					/* alloca pool_size threads*/
					if(addn_worker(pool, n) == -1){
						perror("addn_worker");
						pthread_exit(NULL);
					}
				}
				else if(fd == fd0_usr2_pipe){/* decrementa di una unità il numero di thread Worker nel pool*/
					SYSCALL_EXIT(nread, read(fd0_usr2_pipe, &n, sizeof(int)), "read");
					if(nread == 0){
						perror("FATAL ERROR: fd0_usr2_pipe");
						pthread_exit(NULL);
					}

					/* alloca pool_size threads*/
					if(removen_worker(pool, n) == -1){
						perror("removen_worker");
						pthread_exit(NULL);
					}
				}
			}
		}
	}
}

/**
 * e' una funzione sig_ricevitore, dopo riceuti i segnali, fa corrisponde
 * azioni, se sono ricevuti SIGINT, SIGQUIT, SIGTERM, SIGHUP, notifica la  
 * attuatore termina, se ricevuto SIGUSR1, notifica attuatore incrementa 
 * un thread nel pool, se ricevuto SIGUSR2, notifica attuatore decrementa 
 * un thread nel pool.
 */
static void* sighandler(void *arg){
	sigset_t *mask = ((sighandler_t*)arg)->mask;
	int fd1_sig_pipe = ((sighandler_t*)arg)->fd1_sig_pipe;
	int fd1_usr1_pipe = ((sighandler_t*)arg)->fd1_usr1_pipe;
	int fd1_usr2_pipe = ((sighandler_t*)arg)->fd1_usr2_pipe;
	
	int n = 1, notused;
	for(;;){
		int sig;
		int r = sigwait(mask, &sig);
		if(r != 0){// caso error
			errno = r;
			perror("sigwait");
			pthread_exit(NULL);
		}
		// ricevuto signal
		switch(sig){
		case SIGUSR1:{
			SYSCALL_EXIT(notused, write(fd1_usr1_pipe, &n, sizeof(int)), "write");
			break;
		}
		case SIGUSR2:{
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
		    pthread_exit(NULL);
		default:;
		}
	}
}

/**
 * rilasce la memoria di filename.
 * 
 * @param filename da rilasciare
 */
static void freememory(void *ptr){
	if(ptr) free(ptr);
}

/**
 * clean e close tutti risorse
 * 
 * @param pool puntatore al thread_pool
 * @param ssock array_socket gia connesso
 * @mtx_sock array_mutex per i socket connessioni
 * @param n index di ssock
 * @param sig_pipe per gestire la terminazione
 * @param usr1_pipe per gestire la increamentazione del thread
 * @param usr2_pipe per gestire la decreamentazione del thread
 * 
 * @return 0 On successo, return -1 On error.
 */
static int cleanall(threadpool_t *pool, int ssock[], pthread_mutex_t mtx_sock[], int n, int sig_pipe[], int usr1_pipe[], int usr2_pipe[]){
	int notused;
	/* destroy threadpool*/
	if(pool && threadpool_destroy(pool) == -1){
		perror("master threadpool_destroy");
		return -1;
	}

	if(ssock){
		for (int i = 0; i < n; ++i)
		{
			SYSCALL_EXIT(notused, close(ssock[i]), "close ssock");

			if(pthread_mutex_destroy(&mtx_sock[i]) != 0){
				perror("mtx_sock destroy");
				return -1;
			}
		}
	}

	if(sig_pipe){
		SYSCALL_EXIT(notused, close(sig_pipe[0]), "close sigpipe0");
		SYSCALL_EXIT(notused, close(sig_pipe[1]), "close sigpipe1");
	}
	SYSCALL_EXIT(notused, close(usr1_pipe[0]), "close usr1_pipe0");
	SYSCALL_EXIT(notused, close(usr1_pipe[1]), "close usr1_pipe1");
	SYSCALL_EXIT(notused, close(usr2_pipe[0]), "close usr2_pipe0");
	SYSCALL_EXIT(notused, close(usr2_pipe[1]), "close usr2_pipe1");

	return 0;
}

/**
 * packing un task_arg.
 * 
 * @param cf puntatore task_arg
 * @param dirname puntatore a dir corrente
 * @param filename puntatore a file da contare
 * @param info del i_node file
 * @param ssock socket connessione aperta
 * @param mtx_sock mutex di socket
 * 
 * @return un puntatore cf On successo, return NULL On error.
 */
static countfile_t *packing_task_arg(char *dirname, char *filename, struct stat *info, int ssock, pthread_mutex_t *mtx_sock){
	long len_dirname = 0, len_delim = 0, len_filename = 0, len_filepath;
	if(dirname){
		len_dirname = strlen(dirname);
		len_delim = 1;
	}
	len_filename = strlen(filename);
	len_filepath = len_dirname + len_delim + len_filename;

	do{
		if(len_filepath > MAX_FILENAME_LEN) break;/* filepath troppo lunguo*/

		/* combina filepath*/
		char *filepath = calloc(sizeof(char), len_filepath + 1);
		if(!filepath) break;

		if(dirname){
			strncpy(filepath, dirname, len_filepath);
			strncat(filepath, "/", len_filepath);
			strncat(filepath, filename, len_filepath);
		}
		else strncpy(filepath, filename, len_filepath);

		if(stat(filepath, info) == -1) {
			freememory(filepath);
			printf("error-----------%s\n", filepath);
			perror("stat infofile"); 
			break;
		};

		/* alloca memoria*/
		countfile_t *cf = calloc(sizeof(countfile_t), 1);
		if(!cf){
			free(filepath);
			break;
		}
		cf->mtx_sock = mtx_sock;
		cf->filepath = filepath;
		cf->filesize = (long)info->st_size;
		cf->len_filepath = len_filepath;
		cf->ssock = ssock;
		DEBUG(0,"input un file ");
		DEBUG(0,cf->filepath);
		return cf;
	}while(0);

	return NULL;
}

/**
 * parsing un dir, trova tutti i files nel dir in modo ricorsione, 
 * e aggiunge task nel pool.
 * 
 * @param pool puntatore al thread_pool
 * @param dirname da parsing
 * @param ssock array ai socket connessioni aperte
 * @mtx_sock array_mutex per i socket connessioni 
 * @param n_sock numero socket connessioni 
 * @param num_task numero del task
 * @param delay ritardo tra due add_task
 * 
 * @return 0 On successo, return 1 se pool e' chiuso, return -1 On error.
 */
static int parsing_dir(threadpool_t *pool, char *dirname, int ssock[], pthread_mutex_t mtx_sock[], int n_sock, int *num_task, int delay){
	DIR *dir = NULL;
	struct dirent *file = NULL;
	struct stat info;
	if((dir = opendir(dirname)) == NULL){
		perror("opendir");
		return -1;
	}
	while((errno = 0, file = readdir(dir)) != NULL){
		/* ignora dir . e .. , riduce la allocazione memoria*/
		if(!strcmp(".", file->d_name) || !strcmp("..", file->d_name)) continue;

		countfile_t *cf = NULL;
		*num_task = (*num_task + 1) % n_sock;
		if((cf = packing_task_arg(dirname, file->d_name, &info, ssock[*num_task], &mtx_sock[*num_task])) == NULL) return -1;/* On error*/

		if(S_ISDIR(info.st_mode)){
			int r = parsing_dir(pool, cf->filepath, ssock, mtx_sock, n_sock, num_task, delay);
			free(cf->filepath);/* non serve piu'*/
			freememory(cf);
			if(r == -1) return -1;/* On error*/
			if(r == 1) return 1;/* pool gia' shutdown*/
		}
		else{/* e' un file*/
			int r = add_task(pool, countfile, cf);
			if(r == -1){
				freememory(cf->filepath);
				freememory(cf);
				return -1;/* On error*/
			}
			if(r == 1){
				freememory(cf->filepath);
				freememory(cf);
				return 1;/* pool gia' shutdown*/
			} 

			usleep(delay);/* add successo, setta un ritardo fra prossima add*/
		}
	}
	if(errno != 0) {perror("readdir"); return -1;}
	if(closedir(dir) != 0) {perror("closedir"); return -1;}

	return 0;
}

/**
 * E' una funzione per trovare i files nei argomenti passati e nel dir passata,
 * poi li aggiunge nel task_queue di threadpool. Calcola i risultati e al posto
 * client, invia i risultati a Collector_server. Riceve ancora i segnali, se 
 * sono ricevuti SIGINT, SIGQUIT, SIGTERM, SIGHUP, termina la sua esecuzione,
 * se ricevuto SIGUSR1, incrementa un thread nel pool, se ricevuto SIGUSR2,
 * decrementa un thread nel pool.
 * 
 * @param argc nel main
 * @param argv nel main
 * @param mask i set dei signali da gestire
 * @param sa socket_addr
 * 
 * @return 0 On successo, return 1 se pool e' chiuso, return -1 On errror.
 */
int run_master(int argc, char *argv[], sigset_t *mask, struct sockaddr_un *sa){
	/* inizialliza*/
	int n_thread = NTHREAD;
	int n_sock = NSOCKET;
	int len_task_queue = LEN_TASK_QUEUE;
	int delay = DELAY_MASTER;
	char *dirname = NULL;

	/* acquisire argomenti */
	long arg_n = -1, arg_q = -1, arg_t = -1, arg_s = -1;
	int opt;
	while((opt = getopt(argc, argv, ":n:q:d:t:s:")) != -1){
		switch(opt){
		case 'n':{
			if(isNumber(optarg, &arg_n) && arg_n > 0) n_thread = arg_n;
		}break;
		case 'q':{
			if(isNumber(optarg, &arg_q) && arg_q > 0) len_task_queue = arg_q;
		}break;
		case 'd':{
			dirname = optarg;
		}break;
		case 't':{
			if(isNumber(optarg, &arg_t) && arg_t > 0) delay = arg_t;
		}break;
		case 's':{
			if(isNumber(optarg, &arg_s) && arg_s > 0) n_sock = arg_s;
		}break;
		case ':':{
			fprintf(stderr, "l'opzione '-%c' richiede un argomento, usa DEFAULT\n", opt);
		}break;
		case '?':{
			fprintf(stderr, "l'opzione '-%c' non e' riconoscito\n", opt);
		}break;
		default:;
		}
	}

	/** 
	 * usa 3 pipe senza nome, registra su seletor, sig_pipe per la terminazione 
	 * del MasterWorker, usr1_pipe per notifica thread gestoreMaster incrementa 
	 * un thread nel pool, usr2_pipe invece, decrementa uno.
	 */
	int sig_pipe[2], usr1_pipe[2], usr2_pipe[2], notused;
	memset(sig_pipe, 0 ,sizeof(sig_pipe));
	memset(usr1_pipe, 0, sizeof(usr1_pipe));
	memset(usr2_pipe, 0, sizeof(usr2_pipe));
	SYSCALL_EXIT(notused, pipe(sig_pipe), "pipe");
	SYSCALL_EXIT(notused, pipe(usr1_pipe), "pipe");
	SYSCALL_EXIT(notused, pipe(usr2_pipe), "pipe");

	/* inizialliza thread_arg di sighandler*/
	sighandler_t arg_sigh;
	arg_sigh.mask = mask;
	arg_sigh.fd1_sig_pipe = sig_pipe[1];
	arg_sigh.fd1_usr1_pipe = usr1_pipe[1];
	arg_sigh.fd1_usr2_pipe = usr2_pipe[1];
	/* crea un receiver*/
	taskfun_t sig_receiver;
	sig_receiver.fun = sighandler;
	sig_receiver.arg = &arg_sigh;

	/* crea threadpool, e installa un receiver nel pool*/
	threadpool_t *pool = threadpool_create(n_thread, len_task_queue, &sig_receiver, NULL);
	if(!pool){
		cleanall(NULL, NULL, NULL, 0, sig_pipe, usr1_pipe, usr2_pipe);
		return -1;/* error*/
	}

	/* inizialliza thread_arg di sigmonitor*/
	sigmonitor_t arg_sigm;
	arg_sigm.pool = pool;
	arg_sigm.fd0_sig_pipe = sig_pipe[0];
	arg_sigm.fd0_usr1_pipe = usr1_pipe[0];
	arg_sigm.fd0_usr2_pipe = usr2_pipe[0];
	/* definisce e installa un actuator nel pool*/
	taskfun_t sig_actuator;
	sig_actuator.fun = sigmonitor;
	sig_actuator.arg = &arg_sigm;
	install_monitor(pool, &sig_actuator);

	/* crea n_sock connessione con Collector*/
	int ssock[n_sock];
	memset(ssock, 0, sizeof(ssock));
	/* associa un mutex per ogni socket*/
	pthread_mutex_t mtx_sock[n_sock];
	memset(mtx_sock, 0, sizeof(mtx_sock));
	for (int i = 0; i < n_sock; ++i)
	{
		SYSCALL_EXIT(ssock[i], socket(AF_UNIX, SOCK_STREAM, 0), "socket");
		while(connect(ssock[i], (struct sockaddr*)sa, sizeof(*sa)) == -1){
			if(errno = ENOENT) sleep(1);
			else{
				cleanall(pool, ssock, mtx_sock, i, sig_pipe, usr1_pipe, usr2_pipe);
				perror("connect");
				return -1;/* On error*/
			}
		}
		/* inizialliza mutex*/
		if(pthread_mutex_init(&mtx_sock[i], NULL) != 0){
			if(ssock[i]) SYSCALL_EXIT(notused, close(ssock[i]), "close ssock");
			cleanall(pool, ssock, mtx_sock, i, sig_pipe, usr1_pipe, usr2_pipe);
			perror("mtx_sock init");
			return -1;/* On error*/
		}
	}

	/* inizia add task, trova i files passati*/
	int r = 0, num_task = -1;
	struct stat info;
	while(argv[optind] != NULL){
		/* packing un task_arg cf tipo countfile_t*/
		countfile_t *cf = NULL;
		num_task = (num_task + 1) % n_sock;
		if((cf = packing_task_arg(NULL, argv[optind], &info, ssock[num_task], &mtx_sock[num_task])) == NULL){
			cleanall(pool, ssock, mtx_sock, n_sock, sig_pipe, usr1_pipe, usr2_pipe);
			return -1;/* On error*/
		}

		/** 
		 *  add un task a task_queue, 
		 *  se ritorna 1 signfica threadpool gia' chiuso!!!
		 */
		r = add_task(pool, countfile, cf);
		if(r == -1){
			freememory(cf->filepath);
			freememory(cf);
			cleanall(pool, ssock, mtx_sock, n_sock, sig_pipe, usr1_pipe, usr2_pipe);
			return -1;/* On error*/
		}
		if(r == 1){/* checked pool gia' shutdown*/
			freememory(cf->filepath);
			freememory(cf);
			cleanall(pool, ssock, mtx_sock, n_sock, NULL, usr1_pipe, usr2_pipe);
			return 1;
		} 

		usleep(delay);/* add successo, setta un ritardo fra prossima add*/
		++optind;
	}

	//r = 0;
	/* trova i files nel dir, se c'e*/
	if(dirname){
		struct stat info;
		if(stat(dirname, &info) == -1){
			perror("stat dirname");
			cleanall(pool, ssock, mtx_sock, n_sock, sig_pipe, usr1_pipe, usr2_pipe);
			return -1;/* On error*/
		}

		if(S_ISDIR(info.st_mode)){
			/** 
			 *  parsing i files nel DIR e se trovati, add a task_queue, 
			 *  se ritorna 1 signfica threadpool gia' chiuso!!!
			 */
			r = parsing_dir(pool, dirname, ssock, mtx_sock, n_sock, &num_task, delay);
			if(r == -1){
				cleanall(pool, ssock, mtx_sock, n_sock, sig_pipe, usr1_pipe, usr2_pipe);
				return -1; /* On error*/
			}
			if(r == 1){/* checked pool gia' shutdown*/
				cleanall(pool, ssock, mtx_sock, n_sock, NULL, usr1_pipe, usr2_pipe);
				return 1; 
			}
		}
	}

	/** exit On successo, invia un signal notifica sig_monitor per chiudere threadpool.
	 *  Or usare timeout*/
	SYSCALL_EXIT(notused, kill(getpid(), 2), "kill");

	cleanall(pool, ssock, mtx_sock, n_sock, NULL, usr1_pipe, usr2_pipe);
	return 0;/* exit On successo*/
}
