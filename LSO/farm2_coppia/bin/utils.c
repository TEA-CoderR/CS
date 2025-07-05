/**
 * Incapsula e implementa alcune funzioni utili
 * 
 * @author Yang
 */
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <pthread.h>

#include <utils.h>

/**
 * Verifica una stringa sia un numero.
 * 
 * @param s puntatore alla stringa da verificare
 * @param val puntatore alla numero lungo da memorizzare il risultato
 * 
 * @return 1 on Successo, 0 on Error.
 */
bool isNumber(const char *s, long *val){
    char* e = NULL;
    *val = strtol(s, &e, 0);
    if(e != NULL && *e == (char)0) return true;
    return false;
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





















// /**
//  * Incapsula e implementa alcune funzioni utili
//  * 
//  * @author Yang
//  */
// #include <stdio.h>
// #include <stdlib.h>
// #include <string.h>
// #include <errno.h>
// #include <unistd.h>
// #include <pthread.h>

// #include "utils.h"

// // #define true 1
// // #define false 0
// // #define bool int

// #define DEBUG(f,m) \
//     if(f) {fprintf(stderr, "%s\n", m);}
// #define EXIT_F(e) do{   \
//     perror(e); exit(EXIT_FAILURE); }while(0);
// // #define CHECK_NULL_EXIT(r,c,v,e)  \
// // 	if((r = c) == v) {errno = r, perror(e); exit(errno);}
// #define SYSCALL_EXIT(r,c,e)    \
// 	if((r = c) == -1) {errno = r, perror(e); exit(errno);}
// #define EC_NULL(c,e)    \
// 	if(c == NULL) {perror(e); exit(EXIT_FAILURE);}


// /**
//  * Verifica una stringa sia un numero.
//  * 
//  * @param s puntatore alla stringa da verificare
//  * @param val puntatore alla numero lungo da memorizzare il risultato
//  * 
//  * @return 1 on Successo, 0 on Error.
//  */
// bool isNumber(const char *s, long *val){
// 	char* e = NULL;
// 	*val = strtol(s, &e, 0);
// 	if(e != NULL && *e == (char)0) return true;
// 	return false;
// }

// /**
//  * Read "n" bytes from a descriptor, evita la lettura parziale.
//  * 
//  * @param fd descriptor da leggere
//  * @param ptr puntarore alla buffer
//  * @param n size of buffer
//  * 
//  * @return il numero letto reale.
//  */
// ssize_t readn(int fd, void *ptr, size_t n) {  
//    size_t   nleft;
//    ssize_t  nread;
 
//    nleft = n;
//    while (nleft > 0) {
//      if((nread = read(fd, ptr, nleft)) < 0) {
//         if (nleft == n) return -1; /* error, return -1 */
//         else break; /* error, return amount read so far */
//      } else if (nread == 0) break; /* EOF */
//      nleft -= nread;
//      ptr   += nread;
//    }
//    return(n - nleft); /* return >= 0 */
// }
 
//  /**
//   * Write "n" bytes to a descriptor, evita la scrittura parziale. 
//   * 
//   * @param fd descriptor da scrivere
//   * @param ptr puntarore alla buffer
//   * @param n numero da scrivere
//   * 
//   * @return il numero scritto reale.
//   */
// ssize_t writen(int fd, void *ptr, size_t n) {  
//    size_t   nleft;
//    ssize_t  nwritten;
 
//    nleft = n;
//    while (nleft > 0) {
//      if((nwritten = write(fd, ptr, nleft)) < 0) {
//         if (nleft == n) return -1; /* error, return -1 */
//         else break; /* error, return amount written so far */
//      } else if (nwritten == 0) break; 
//      nleft -= nwritten;
//      ptr   += nwritten;
//    }
//    return(n - nleft); /* return >= 0 */
// }

// /**
//  * LOCK mutex
//  * 
//  * @oaram mtx 
//  */
// void LOCK(pthread_mutex_t *mtx){
//     int err;
//     if((err = pthread_mutex_lock(mtx)) != 0){
//         errno = err;
//         perror("lock");
//         pthread_exit((void*)&errno);
//     }
//     //else printf("locked ");		
// }

// /**
//  * UNLOCK mutex
//  * 
//  * @oaram mtx 
//  */
// void UNLOCK(pthread_mutex_t *mtx){
//     int err;
//     if((err = pthread_mutex_unlock(mtx)) != 0){
//         errno = err;
//         perror("unlock");
//         pthread_exit((void *)&errno);
//     }
//     //else printf("unlocked\n");
// }

// /**
//  * WAIT cond on mutex
//  * 
//  * @param cond
//  * @oaram mtx 
//  */
// void WAIT(pthread_cond_t *cond, pthread_mutex_t *mtx){
//     int err;
//     if((err = pthread_cond_wait(cond, mtx)) != 0){
//         errno = err;
//         perror("wait");
//         pthread_exit((void*)&errno);
//     }
// }

// /**
//  * SIGNAL cond
//  * 
//  * @param cond
//  */
// void SIGNAL(pthread_cond_t *cond){
//     int err;
//     if((err = pthread_cond_signal(cond)) != 0){
//         errno = err;
//         perror("signal");
//         pthread_exit((void *)&errno);
//     }
// }

// /**
//  * BROADCAST cond
//  * 
//  * @param cond
//  */
// void BROADCAST(pthread_cond_t *cond){
//     int err;
//     if((err = pthread_cond_broadcast(cond)) != 0){
//         errno = err;
//         perror("broadcast");
//         pthread_exit((void *)&errno);
//     }
// }

// /**
//  * LOCK_RETURN mutex
//  * 
//  * @oaram mtx 
//  */
// int LOCK_RETURN(pthread_mutex_t *mtx, int r){
//     int err;
//     if((err = pthread_mutex_lock(mtx)) != 0){
//         errno = err;
//         perror("lock");
//         return r;
//     }
//     //else printf("locked ");       
// }

// /**
//  * UNLOCK_RETURN mutex
//  * 
//  * @oaram mtx 
//  */
// int UNLOCK_RETURN(pthread_mutex_t *mtx, int r){
//     int err;
//     if((err = pthread_mutex_unlock(mtx)) != 0){
//         errno = err;
//         perror("unlock");
//         return r;
//     }
//     //else printf("unlocked\n");
// }

// /**
//  * WAIT_RETURN cond on mutex
//  * 
//  * @param cond
//  * @oaram mtx 
//  */
// int WAIT_RETURN(pthread_cond_t *cond, pthread_mutex_t *mtx, int r){
//     int err;
//     if((err = pthread_cond_wait(cond, mtx)) != 0){
//         errno = err;
//         perror("wait");
//         return r;
//     }
// }

// /**
//  * SIGNAL_RETURN cond
//  * 
//  * @param cond
//  */
// int SIGNAL_RETURN(pthread_cond_t *cond, int r){
//     int err;
//     if((err = pthread_cond_signal(cond)) != 0){
//         errno = err;
//         perror("signal");
//         return r;
//     }
// }

// /**
//  * BROADCAST_RETURN cond
//  * 
//  * @param cond
//  */
// int BROADCAST_RETURN(pthread_cond_t *cond, int r){
//     int err;
//     if((err = pthread_cond_broadcast(cond)) != 0){
//         errno = err;
//         perror("broadcast");
//         return r;
//     }
// }