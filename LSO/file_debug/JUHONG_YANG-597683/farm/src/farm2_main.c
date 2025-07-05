/***********************************************************************
*** progetto LSO farm
*** 
*** 
*** 
*** @author Yang Juhong
***********************************************************************/
#define _POSIX_C_SOURCE 200112L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <signal.h>

#include <utils.h>
#include <master.h>
#include <collector.h>

#ifndef SOCKETNAME
#define SOCKETNAME "./farm2.sck"
#endif

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
	int notused;
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
    memset(s, 0 ,sizeof(struct sigaction));
    s->sa_handler = SIG_IGN;
    SYSCALL_EXIT(notused, sigaction(SIGPIPE, s, NULL), "sigaction");
}

/**
 * unlink SOCKETNAME.
 */
static void cleansock(){
	unlink(SOCKETNAME);
	DEBUG(0, "clean sok ok\n");
}

/**
 * usage.
 */
static void printf_usage(char *progname){
	fprintf(stderr, 
		"Usage :%s file.dat [file*.dat] -d dirname -n nthread -q lenqueue -t delay -s nsocket\n",
		 progname);
}

int main(int argc, char *argv[])
{
	if(argc < 2){
		printf_usage(argv[0]);
		exit(EXIT_FAILURE);
	}
	cleansock();
	atexit(cleansock);
	/* define e maschera i signali*/
	sigset_t mask, oldmask;
	struct sigaction s;
	mascheraIgnoraSig(&mask, &oldmask, &s);
	/* define e inizialliza socket*/
	struct sockaddr_un sa;
	inizialliza(&sa);

	/* fork a process per eseguire collector*/
	int pid, notused;;
	SYSCALL_EXIT(pid, fork(), "fork");
	if(pid == 0){// processo server Collector
		if(run_collector(&sa) == -1) return -1;
	}
	else{/* processo client MasterWorker*/
		if(run_master(argc, argv, &mask, &sa) == -1) return -1;	

		SYSCALL_EXIT(notused, waitpid(pid, NULL, 0), "waitpid");
	}
	return 0;
}