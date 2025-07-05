/**
 * Implementare la interfaccia "queue.h"
 * 
 * @author Yang
 */
#include <stdlib.h>
#include <pthread.h>

#include <queue.h>
#include <utils.h>

#define SIZEQ sizeof(Queue_t)
#define SIZEN sizeof(Node_t)
/** 
 * Alloca ed inizialliza una coda.
 * 
 * @return un puntatore alla memoria allocata. On error, return NULL.
 */
Queue_t* initQueue(){
	Queue_t *q = calloc(SIZEQ, 1);
	if(!q) return NULL;
	q->head = calloc(SIZEN, 1);
	if(!q->head) return NULL;
	q->head->data = NULL;
	q->head->next = NULL;
	q->tail = q->head;
	q->qlen = 0;
	if(pthread_mutex_init(&q->mtx, NULL) != 0){
		perror("mutex init");
		return NULL;
	}
	if(pthread_cond_init(&q->empty, NULL) != 0){
		perror("cond init");
		if(&q->mtx) pthread_mutex_destroy(&q->mtx);
		return NULL;
	}
	if(pthread_cond_init(&q->full, NULL) != 0){
		perror("cond init");
		if(&q->mtx) pthread_mutex_destroy(&q->mtx);
		if(&q->empty) pthread_cond_destroy(&q->empty);
		return NULL;
	}
	return q;
}

/** 
 * Cancella una coda allocata.
 * 
 * @param q puntatore alla coda da cancellare
 */
void destroyQueue(Queue_t *q){
	while(q->head != q->tail){
		Nodeptr tmp = q->head;
		q->head = q->head->next;
		free(tmp);
	}
	if(q->head) free(q->head);//manca un solo node
	if(&q->mtx) pthread_mutex_destroy(&q->mtx);
	if(&q->empty) pthread_cond_destroy(&q->empty);
	if(&q->full) pthread_cond_destroy(&q->full);
	free(q);
}

/** 
 * Verifica la coda sia vuota.
 * 
 * @param q puntatore alla coda da verificare
 * 
 * @return 1 se e' vuota, else return 0.
 */
int isEmpty(Queue_t *q){
	return (q->qlen == 0);
}

/** 
 * Verifica la coda sia piena.
 * 
 * @param q puntatore alla coda da verificare
 * 
 * @return 1 se e' piena, else return 0.
 */
int isFull(Queue_t *q){
	return (q->qlen == q->maxsize);
}

/** 
 * inserisce una data nella coda.
 * 
 * @param q puntatore alla coda da inserire
 * @param e puntatore alla data da inserire
 * 
 * @return 0 on Successo, return -1 on Error.
 */
int enQueue(Queue_t *q, void* e){
	if(!q || !e){//controllo i parametri siano valido
		errno = EINVAL;
		return -1;
	}
	/* crea un node*/
	Nodeptr new = calloc(SIZEN, 1);
	if(!new) return -1;
	new->data = NULL;
	new->next = NULL;
	/* prova a prendere mutex per operazione push*/
	LOCK(&q->mtx);
	while(isFull(q)) WAIT(&q->full, &q->mtx);
	q->tail->data = e;
	q->tail->next = new;
	q->tail = q->tail->next;
	++q->qlen;
	SIGNAL(&q->empty);
	UNLOCK(&q->mtx);
	return 0;
}

/** 
 * Estrae una data dalla coda.
 * 
 * @param q puntatore alla coda da estrarre
 * 
 * @return un puntatore alla data.
 */
void* deQueue(Queue_t *q){
	if(!q){//controllo i parametri siano valido
		errno = EINVAL;
		return NULL;
	}

	LOCK(&q->mtx);
	while(isEmpty(q)) WAIT(&q->empty, &q->mtx);
	void *data = q->head->data;
	Nodeptr tmp = q->head;
	q->head = q->head->next;
	--q->qlen;
	SIGNAL(&q->full);
	UNLOCK(&q->mtx);

	free(tmp);
	return data;
}