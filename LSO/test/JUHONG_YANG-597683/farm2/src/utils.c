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
#include <sys/types.h>
#include <sys/uio.h>

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
   char *tmp_ptr = NULL;

   nleft = n;
   tmp_ptr = (char*)ptr;
   while (nleft > 0) {
     if((nread = read(fd, tmp_ptr, nleft)) < 0) {
        if (nleft == n) return -1; /* error, return -1 */
        else break; /* error, return amount read so far */
     } else if (nread == 0) break; /* EOF */
     nleft -= nread;
     tmp_ptr   += nread;
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
   char *tmp_ptr = NULL;
 
   nleft = n;
   tmp_ptr = (char*)ptr;
   while (nleft > 0) {
     if((nwritten = write(fd, tmp_ptr, nleft)) < 0) {
        if (nleft == n) return -1; /* error, return -1 */
        else break; /* error, return amount written so far */
     } else if (nwritten == 0) break; 
     nleft -= nwritten;
     tmp_ptr   += nwritten;
   }
   return(n - nleft); /* return >= 0 */
}

/**
 * Read "n" struct iovec from a descriptor, evita la lettura parziale.
 * 
 * @param fd descriptor da leggere
 * @param ptr puntarore alla iovec
 * @param n size of iovec
 * 
 * @return il numero letto reale.
 */
ssize_t readvn(int fd, void *ptr, size_t n) {  
   size_t   nleft;
   ssize_t  nread;
   struct iovec *iov = NULL;

   nleft = n;
   iov = (struct iovec *)ptr;
   while (nleft > 0) {
     if((nread = readv(fd, iov, nleft)) < 0) {
        if (nleft == n) return -1; /* error, return -1 */
        else break; /* error, return amount read so far */
     } else if (nread == 0) break; /* EOF */
     size_t consume = nread;
     while(consume > 0){
         if(consume >= iov->iov_len){/* per long intero*/
            consume -= iov->iov_len;
            --nleft;
            //printf("consume:%ld nleft:%ld iov_len:%ld\n", consume, nleft, iov->iov_len);
            ++iov;
         }
         else if(consume >= strlen((char*)(iov->iov_base))){/* per la stringa*/
            consume -= strlen((char*)(iov->iov_base));
            --nleft;
            //printf("consume:%ld nleft:%ld iov_len:%ld\n", consume, nleft, iov->iov_len);
            ++iov;
         }
         else{/* la parte restante*/
            iov->iov_len -= consume;
            char *tmp_ptr = (char*)iov->iov_base;
            tmp_ptr += consume;
            //iov->iov_base += consume;
            consume = 0;
         }
     }
   }
   return(n - nleft); /* return >= 0 */
}

/**
 * Write "n" struct iovec from a descriptor, evita la scrittura parziale.
 * 
 * @param fd descriptor da scrivere
 * @param ptr puntarore alla iovec
 * @param n size of iovec
 * 
 * @return il numero scritto reale.
 */
ssize_t writevn(int fd, void *ptr, size_t n) {  
   size_t   nleft;
   ssize_t  nwritten;
   struct iovec *iov = NULL;

   nleft = n;
   iov = (struct iovec *)ptr;
   while (nleft > 0) {
     if((nwritten = writev(fd, iov, nleft)) < 0) {
        if (nleft == n) return -1; /* error, return -1 */
        else break; /* error, return amount read so far */
     } else if (nwritten == 0) break; /* EOF */
     size_t consume = nwritten;
     while(consume > 0){
         if(consume >= iov->iov_len){
            consume -= iov->iov_len;
            --nleft;
            //printf("consume:%ld nleft:%ld iov_len:%ld\n", consume, nleft, iov->iov_len);
            ++iov;
         }
         else{/* la parte restante*/
            iov->iov_len -= consume;
            char *tmp_ptr = (char*)iov->iov_base;
            tmp_ptr += consume;
            //iov->iov_base += consume;
            consume = 0;
         }
     }
   }
   return(n - nleft); /* return >= 0 */
}