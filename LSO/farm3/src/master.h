#ifndef MASTER_H_
#define MASTER_H_

// #include <stdio.h>
// #include <stdlib.h>
// #include <string.h>
// #include <unistd.h>
// #include <errno.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/stat.h>


//#include <utils.h>
#include <threadpool.h>
#include <countfile.h>


/** 
 *  definisce una struttura sighandler_t per memorizzare i dati a
 *  passare a thread sighandler.
 * 
 * @var mask set dei segnali da gestire
 * @var fd1_sig_pipe lato scrittura del pipe sig_pipe
 * @var fd1_usr1_pipe lato scrittura del pipe usr1_pipe
 * @var fd1_usr2_pipe lato scrittura del pipe usr2_pipe
 */
typedef struct{
	sigset_t *mask;
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
	threadpool_t *pool;
	int fd0_sig_pipe;
	int fd0_usr1_pipe;
	int fd0_usr2_pipe;
}sigmonitor_t;


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
int run_master(int argc, char *argv[], sigset_t *mask, struct sockaddr_un *sa);

#endif