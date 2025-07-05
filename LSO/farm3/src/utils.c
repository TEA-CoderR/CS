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
