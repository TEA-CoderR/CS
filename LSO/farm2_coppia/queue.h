/** 
 * @file
 * 
 * Definisce una semplice linkcoda concorrente limitata.
 * 
 * @author Yang
 */
#ifndef QUEUE_H_
#define QUEUE_H_

#include <pthread.h>
/** 
 * Node di base
 */
typedef struct node{
    void *data;
    struct node *next;
}node_t;

typedef node_t* nodeptr;

/** 
 * Definisce la struttura dati linkcoda concorrente.
 * Accesso della coda deve essere SEMPRE in modo mutuamente esclusivo.
 * Pop da <head> e push a <tail>, WAIT se la coda e' vuota o piena.
 */
typedef struct Queue
{
    nodeptr head;
    nodeptr tail;
    int maxsize;
    int qlen;
    pthread_mutex_t mtx;
    pthread_cond_t empty;
    pthread_cond_t full;
}Queue_t;

/** 
 * Alloca ed inizialliza una coda.
 * 
 * @return un puntatore alla memoria allocata. On error, return NULL.
 */
Queue_t* initQueue();

/** 
 * Cancella una coda allocata.
 * 
 * @param q puntatore alla coda da cancellare
 */
void destroyQueue(Queue_t *q);

/** 
 * Verifica la coda sia vuota.
 * 
 * @param q puntatore alla coda da verificare
 * 
 * @return 1 se e' vuota, else return 0.
 */
int isEmpty(Queue_t *q);

/** 
 * Verifica la coda sia piena.
 * 
 * @param q puntatore alla coda da verificare
 * 
 * @return 1 se e' piena, else return 0.
 */
int isFull(Queue_t *q);

/** 
 * inserisce una data nella coda.
 * 
 * @param q puntatore alla coda da inserire
 * @param e puntatore alla data da inserire
 * 
 * @return 0 on Successo, return -1 on Error.
 */
int enQueue(Queue_t *q, void* e);

/** 
 * Estrae una data dalla coda.
 * 
 * @param q puntatore alla coda da estrarre
 * 
 * @return un puntatore alla data.
 */
void* deQueue(Queue_t *q);

#endif /*QUEUE_H_*/