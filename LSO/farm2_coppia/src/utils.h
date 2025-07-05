/**
 * Incapsula alcune funzioni utili
 * 
 * @autor Yang
 */
#ifndef UTILS_H_
#define UTILS_H_

#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <pthread.h>


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

#endif /*UTILS_H_*/