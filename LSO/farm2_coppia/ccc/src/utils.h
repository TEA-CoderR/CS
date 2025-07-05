/**
 * Incapsula alcune funzioni utili
 * 
 * @author Yang
 */
#ifndef UTILS_H_
#define UTILS_H_

#include <pthread.h>

#define true 1
#define false 0
#define bool int

// #define DEBUG(f,m) \
//     if(f) {fprintf(stderr, "%s\n", m);}
// #define EXIT_F(e) do{   \
//     perror(e); exit(EXIT_FAILURE); }while(0);
// // #define CHECK_NULL_EXIT(r,c,v,e)  \
// //  if((r = c) == v) {errno = r, perror(e); exit(errno);}
// #define SYSCALL_EXIT(r,c,e)    \
//     if((r = c) == -1) {errno = r, perror(e); exit(errno);}
// #define EC_NULL(c,e)    \
//     if(c == NULL) {perror(e); exit(EXIT_FAILURE);}

/**
 * Verifica una stringa sia un numero.
 * 
 * @param s puntatore alla stringa da verificare
 * @param val puntatore alla numero lungo da memorizzare il risultato
 * 
 * @return 1 on Successo, 0 on Error.
 */
bool isNumber(const char *s, long *val);

/**
 * Read "n" bytes from a descriptor, evita la lettura parziale.
 * 
 * @param fd descriptor da leggere
 * @param ptr puntarore alla buffer
 * @param n size of buffer
 * 
 * @return il numero letto reale.
 */
ssize_t readn(int fd, void *ptr, size_t n);
 
 /**
  * Write "n" bytes to a descriptor, evita la scrittura parziale. 
  * 
  * @param fd descriptor da scrivere
  * @param ptr puntarore alla buffer
  * @param n numero da scrivere
  * 
  * @return il numero scritto reale.
  */
ssize_t writen(int fd, void *ptr, size_t n);

/**
 * LOCK mutex
 * 
 * @oaram mtx 
 */
void LOCK(pthread_mutex_t *mtx);

/**
 * UNLOCK mutex
 * 
 * @oaram mtx 
 */
void UNLOCK(pthread_mutex_t *mtx);

/**
 * WAIT cond on mutex
 * 
 * @param cond
 * @oaram mtx 
 */
void WAIT(pthread_cond_t *cond, pthread_mutex_t *mtx);

/**
 * SIGNAL cond
 * 
 * @param cond
 */
void SIGNAL(pthread_cond_t *cond);

/**
 * LOCK_RETURN mutex
 * 
 * @oaram mtx 
 */
int LOCK_RETURN(pthread_mutex_t *mtx, int r);

/**
 * UNLOCK_RETURN mutex
 * 
 * @oaram mtx 
 */
int UNLOCK_RETURN(pthread_mutex_t *mtx, int r);

/**
 * WAIT_RETURN cond on mutex
 * 
 * @param cond
 * @oaram mtx 
 */
int WAIT_RETURN(pthread_cond_t *cond, pthread_mutex_t *mtx, int r);

/**
 * SIGNAL_RETURN cond
 * 
 * @param cond
 */
int SIGNAL_RETURN(pthread_cond_t *cond, int r);

/**
 * BROADCAST_RETURN cond
 * 
 * @param cond
 */
int BROADCAST_RETURN(pthread_cond_t *cond, int r);

#endif /*UTILS_H_*/