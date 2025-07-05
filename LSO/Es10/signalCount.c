#include <stdio.h>
#include <signal.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <errno.h>

#define EXIT_F(m)		\
	(perror(m), exit(EXIT_FAILURE));
#define EC_MINUS1(e,c,m)  \
	if((e = c) == -1) {errno = e, perror(m); exit(errno);}
#define EC_NULL(s,m)    \
	if(s == NULL) {perror(m); exit(EXIT_FAILURE);}
#define N 32

int e;
volatile sig_atomic_t nSIGINT = 0;
volatile sig_atomic_t nSIGTSTP = 0;
volatile sig_atomic_t toclose = 0;
volatile sig_atomic_t sigtstpflag = 0;
// void gestore_SIGINT(int sig){
//     ++n_SIGINT;
// }
// void gestore_SIGTSTP(int sig){
//     //EC_MINUS1(e, write(1, buf, 1), "write");
//     ++n_SIGTSTP;
//     n_SIGINT = 0;
// }
// void gestore_SIGALRM(int sig){
//     EC_MINUS1(e, write(1, "SIG_ALRM catturato\n", 19), "write");
//     if(toclose) _exit(EXIT_FAILURE);
// }
static void sigwaithandler(int sig){
    switch(sig){
    case SIGINT:{
        ++nSIGINT;
        break;
    }
    case SIGTSTP:{
        ++nSIGTSTP;
        sigtstpflag = 1;
        break;
    }
    case SIGALRM:{
        EC_MINUS1(e, write(1, "SIG_ALRM catturato\n", 19), "write");
        if(toclose) _exit(EXIT_FAILURE);
    }
    default:;
    }
}
static void sighandler(int sig){
    switch(sig){
    case SIGINT:{
        ++nSIGINT;
        break;
    }
    case SIGTSTP:{
        ++nSIGTSTP;
        sigtstpflag = 1;
        break;
    }
    case SIGALRM:{
        EC_MINUS1(e, write(1, "SIG_ALRM catturato\n", 19), "write");
        if(toclose) _exit(EXIT_FAILURE);
    }
    default:;
    }
}
int main(int argc, char const *argv[])
{
    char buf[N];
    /* use sigwait*/
    // sigset_t set;
    // int sig;
    // sigemptyset(&set);
    // sigaddset(&set, SIGINT);
    // sigaddset(&set, SIGTSTP);
    // sigaddset(&set, SIGALRM);
    // EC_MINUS1(e, pthread_sigmask(SIG_SETMASK, &set, NULL), "pthread_sigmask");

    /* use pause*/
    sigset_t set, oldset;
    sigemptyset(&set);
    sigaddset(&set, SIGINT);
    sigaddset(&set, SIGTSTP);
    sigaddset(&set, SIGALRM);
    /* maschera i segnali prima di installare*/
    EC_MINUS1(e, pthread_sigmask(SIG_SETMASK, &set, &oldset), "pthread_sigmask");
    struct sigaction s;
    memset(&s, 0 ,sizeof(s));
    s.sa_handler = sighandler;
    sigset_t handlermask;
    sigemptyset(&handlermask);
    sigaddset(&handlermask, SIGINT);
    sigaddset(&handlermask, SIGTSTP);
    sigaddset(&handlermask, SIGALRM);
    s.sa_flags = SA_RESTART;
    EC_MINUS1(e, sigaction(SIGINT, &s, NULL), "sigaction");
    EC_MINUS1(e, sigaction(SIGTSTP, &s, NULL), "sigaction");
    EC_MINUS1(e, sigaction(SIGALRM, &s, NULL), "sigaction");
    /* reset oldset*/
    EC_MINUS1(e, pthread_sigmask(SIG_SETMASK, &oldset, NULL), "pthread_sigmask");

    while(1){
        if(sigtstpflag == 1){
            printf("ricevuto %d SIGINT\n", nSIGINT);
            sigtstpflag = 0;
            nSIGINT = 0;
        }
        if(nSIGTSTP == 3){
            alarm(10);
            toclose = 1;
            printf("quit after 10s, do u want to quit??? yes/no\n");
            while((e = read(0, buf, N)) != -1 && strncmp(buf, "yes", 3) && strncmp(buf, "no", 2)){
                printf("yes or no\n");
            }
            if(e == -1){
                perror("read");
            }
            else{
                if(!strncmp(buf, "yes", 3)){
                    exit(EXIT_SUCCESS);
                }
                else{
                    toclose = 0;
                    nSIGTSTP = 0;
                }
            }
        }
        /* usepause*/
        pause();

        /* use sigwait*/
        // sigwait(&set, &sig);
        // sigwaithandler(sig);
    }
    return 0;
}

