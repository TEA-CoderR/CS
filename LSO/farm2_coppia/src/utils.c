/**
 * Incapsula e implementa alcune funzioni utili
 * 
 * @autor Yang
 */
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <pthread.h>


#define EXIT_F(e)		\
	(perror(e), exit(EXIT_FAILURE));
// #define CHECK_NULL_EXIT(r,c,v,e)  \
// 	if((r = c) == v) {errno = r, perror(e); exit(errno);}
#define SYSCALL_EXIT(r,c,e)    \
	if((r = c) == -1) {errno = r, perror(e); exit(errno);}
#define EC_NULL(c,e)    \
	if(c == NULL) {perror(e); exit(EXIT_FAILURE);}

/**
 * Verifica una stringa sia un numero.
 * 
 * @param s puntatore alla stringa da verificare
 * @param val puntatore alla numero lungo da memorizzare il risultato
 * 
 * @return 1 on Successo, 0 on Error.
 */
int isNumber(const char *s, long *val){
	char* e = NULL;
	*val = strtol(s, &e, 0);
	if(e != NULL && *e == (char)0) return 1;
	return 0;
}

/**
 * Read "n" bytes from a descriptor, evita la lettura parziale.
 * 
 * @param fd descriptor da leggere
 * @param ptr puntarore alla buffer
 * @param n size of buffer
 * 
 * @return il numero letto reale.
 */
ssize_t readn(int fd, void *ptr, size_t n) {  
   size_t   nleft;
   ssize_t  nread;
 
   nleft = n;
   while (nleft > 0) {
     if((nread = read(fd, ptr, nleft)) < 0) {
        if (nleft == n) return -1; /* error, return -1 */
        else break; /* error, return amount read so far */
     } else if (nread == 0) break; /* EOF */
     nleft -= nread;
     ptr   += nread;
   }
   return(n - nleft); /* return >= 0 */
}
 
 /**
  * Write "n" bytes to a descriptor, evita la scrittura parziale. 
  * 
  * @param fd descriptor da scrivere
  * @param ptr puntarore alla buffer
  * @param n numero da scrivere
  * 
  * @return il numero scritto reale.
  */
ssize_t writen(int fd, void *ptr, size_t n) {  
   size_t   nleft;
   ssize_t  nwritten;
 
   nleft = n;
   while (nleft > 0) {
     if((nwritten = write(fd, ptr, nleft)) < 0) {
        if (nleft == n) return -1; /* error, return -1 */
        else break; /* error, return amount written so far */
     } else if (nwritten == 0) break; 
     nleft -= nwritten;
     ptr   += nwritten;
   }
   return(n - nleft); /* return >= 0 */
}

/**
 * LOCK mutex
 * 
 * @oaram mtx 
 */
void LOCK(pthread_mutex_t *mtx){
    int err;
    if((err = pthread_mutex_lock(mtx)) != 0){
        errno = err;
        perror("lock");
        pthread_exit((void*)&errno);
    }
    //else printf("locked ");		
}

/**
 * UNLOCK mutex
 * 
 * @oaram mtx 
 */
void UNLOCK(pthread_mutex_t *mtx){
    int err;
    if((err = pthread_mutex_unlock(mtx)) != 0){
        errno = err;
        perror("unlock");
        pthread_exit((void *)&errno);
    }
    //else printf("unlocked\n");
}

/**
 * WAIT cond on mutex
 * 
 * @param cond
 * @oaram mtx 
 */
void WAIT(pthread_cond_t *cond, pthread_mutex_t *mtx){
    int err;
    if((err = pthread_cond_wait(cond, mtx)) != 0){
        errno = err;
        perror("wait");
        pthread_exit((void*)&errno);
    }
}

/**
 * SIGNAL cond
 * 
 * @param cond
 */
void SIGNAL(pthread_cond_t *cond){
    int err;
    if((err = pthread_cond_signal(cond)) != 0){
        errno = err;
        perror("signal");
        pthread_exit((void *)&errno);
    }
}