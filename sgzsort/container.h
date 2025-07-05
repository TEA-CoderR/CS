#ifndef CONTAINER_H_
#define CONTAINER_H_

#include <pthread.h>

/* definisce un link table per memorizzare i risultati ricevuti*/
typedef struct node_s{
	int priority;
	char *id;
	struct node_s *next;
}node_t;

typedef struct{
	node_t *head_result;
	//pthread_mutex_t mtx;/* lock la struttura*/
}container_t;

/**
 * crea un container per memorizzare i risulti.
 *
 * @return un puntatore del container allocato On successo, return NULL On error.
 */ 
container_t *container_create();

/**
 * destroy un container, puo chiamare solo da un thread.
 * 
 * @param container da cancella
 * 
 * @return 0 On successo, return -1 On error.
 */
int container_destroy(container_t *container);

/**
 * add un new_result nel container.
 * 
 * @param container dove memorizzare i results
 * @param new_filepath da aggiungere
 * 
 * @return 0 On successo, return -1 On error.
 */
int add_id(container_t *container, int priority, char *new_id);

/**
 * remove un new_result nel container.
 * 
 * @param container dove memorizzare i results
 * @param new_filepath da cancellare
 * 
 * @return 0 On successo, return -1 On error.
 */
void* remove_id(container_t *container, char *id, int len);

node_t* remove_node(container_t *container, node_t *node, int len);

//node_t* add_node(container_t *container, node_t *node);

/**
 * stampa i risultati, va bene non acquisire mutex, tollerare alcune 
 * imprecisioni per le prestazioni.
 * 
 * @param container dove memorizzare i results
 * 
 * @return 0 On successo, return -1 On error.
 */
int print_results(container_t *container);

#endif /*CONTAINER_H_*/