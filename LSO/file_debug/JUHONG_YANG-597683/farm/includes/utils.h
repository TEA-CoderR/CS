/**
 * Incapsula alcune funzioni utili
 * 
 * @author Yang
 */
#ifndef UTILS_H_
#define UTILS_H_

#include <stdio.h>
#include <errno.h>
#include <pthread.h>
#include <sys/types.h>

#define true 1
#define false 0
#define bool int
#define MSG 0 /* flag printf*/

#define DEBUG(f,m)                                      \
    if(f) {fprintf(stderr, "%s\n", m); fflush(stdout);}

#define PRINTF_MSG(f,m)                                     \
    if(f) {fprintf(stderr, "%s\n", m);}

#define EXIT_F(e) do{                                           \
    perror(e); exit(EXIT_FAILURE); }while(0);

#define CHECK_NULL_RETURN(r,c,e,b)                                  \
    if((r = c) == NULL) {perror(e); return b;}

#define SYSCALL_EXIT(r,c,e)                                             \
    if((r = c) == -1) {errno = r, perror(e); exit(errno);}

#define SYSCALL_RETURN(r,c,e,b)                                            \
    if((r = c) == -1) {errno = r, perror(e); return b;}

#define EC_NULL(c,e)                                                          \
    if(c == NULL) {perror(e); exit(EXIT_FAILURE);}

/**
 * LOCK mutex
 * 
 * @oaram mtx 
 */
#define LOCK(mtx) do{                                \
        int err;                                      \
        if((err = pthread_mutex_lock(mtx)) != 0){      \
            errno = err;                                \
            perror("lock");                              \
            pthread_exit((void*)&errno);                  \
        }}while(0);                                               

/**
 * UNLOCK mutex
 * 
 * @oaram mtx 
 */
#define UNLOCK(mtx) do{                              \
        int err;                                      \
        if((err = pthread_mutex_unlock(mtx)) != 0){    \
            errno = err;                                \
            perror("unlock");                            \
            pthread_exit((void*)&errno);                  \
        }}while(0);                                               

/**
 * WAIT cond on mutex
 * 
 * @param cond
 * @oaram mtx 
 */
#define WAIT(cond, mtx) do{                             \
        int err;                                         \
        if((err = pthread_cond_wait(cond, mtx)) != 0){    \
            errno = err;                                   \
            perror("wait");                                 \
            pthread_exit((void*)&errno);                     \
        }}while(0);                                                 

/**
 * SIGNAL cond
 * 
 * @param cond
 */
#define SIGNAL(cond) do{                         \
        int err;                                  \
        if((err = pthread_cond_signal(cond)) != 0){\
            errno = err;                            \
            perror("signal");                        \
            pthread_exit((void *)&errno);             \
        }}while(0);                                          


/**
 * BROADCAST cond
 * 
 * @param cond
 */
#define BROADCAST(cond) do{                            \
        int err;                                        \
        if((err = pthread_cond_broadcast(cond)) != 0){   \
            errno = err;                                  \
            perror("broadcast");                           \
            pthread_exit((void *)&errno);                   \
        }}while(0);                                                



/**
 * LOCK_RETURN mutex
 * 
 * @oaram mtx 
 */
#define LOCK_RETURN(mtx, r) do{                  \
        int err;                                  \
        if((err = pthread_mutex_lock(mtx)) != 0){  \
            errno = err;                            \
            perror("lock");                          \
            return r;                                 \
        }}while(0);                                          


/**
 * UNLOCK_RETURN mutex
 * 
 * @oaram mtx 
 */
#define UNLOCK_RETURN(mtx, r) do{                    \
        int err;                                      \
        if((err = pthread_mutex_unlock(mtx)) != 0){    \
            errno = err;                                \
            perror("unlock");                            \
            return r;                                     \
        }}while(0);                                              


/**
 * WAIT_RETURN cond on mutex
 * 
 * @param cond
 * @oaram mtx 
 */
#define WAIT_RETURN(cond, mtx, r) do{                       \
        int err;                                             \
        if((err = pthread_cond_wait(cond, mtx)) != 0){        \
            errno = err;                                       \
            perror("wait");                                     \
            return r;                                            \
        }}while(0);                                                     


/**
 * SIGNAL_RETURN cond
 * 
 * @param cond
 */
#define SIGNAL_RETURN(cond, r) do{                          \
        int err;                                             \
        if((err = pthread_cond_signal(cond)) != 0){           \
            errno = err;                                       \
            perror("signal");                                   \
            return r;                                            \
        }}while(0);                                                   


/**
 * BROADCAST_RETURN cond
 * 
 * @param cond
 */
#define BROADCAST_RETURN(cond, r) do{                           \
        int err;                                                 \
        if((err = pthread_cond_broadcast(cond)) != 0){            \
            errno = err;                                           \
            perror("broadcast");                                    \
            return r;                                                \
        }}while(0);                                                         
    

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
 * Read "n" struct iovec from a descriptor, evita la lettura parziale.
 * 
 * @param fd descriptor da leggere
 * @param ptr puntarore alla iovec
 * @param n size of iovec
 * 
 * @return il numero letto reale.
 */
ssize_t readvn(int fd, void *ptr, size_t n);

/**
 * Write "n" struct iovec from a descriptor, evita la scrittura parziale.
 * 
 * @param fd descriptor da scrivere
 * @param ptr puntarore alla iovec
 * @param n size of iovec
 * 
 * @return il numero scritto reale.
 */
ssize_t writevn(int fd, void *ptr, size_t n);

#endif /*UTILS_H_*/