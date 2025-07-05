#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <stdbool.h>

#include <container.h>
//#include <utils.h>

/**
 * crea un container per memorizzare i risulti.
 *
 * @return un puntatore del container allocato On successo, return NULL On error.
 */ 
container_t *container_create(){
	container_t *container = NULL;
	do{
		container = calloc(sizeof(container_t), 1);
		if(!container) break;
		container->head_result = NULL;
		/* inizialliza mutex*/
		// if(pthread_mutex_init(&container->mtx, NULL) != 0){
		// 	if(container) free(container);
		// 	perror("mutex init");
		// 	break;
		// }

		return container;
	}while(false);

	return NULL;
}

/**
 * destroy un container, puo chiamare solo da un thread.
 * 
 * @param container da cancella
 * 
 * @return 0 On successo, return -1 On error.
 */
int container_destroy(container_t *container){
	do{
		if(!container) break;
		while(container->head_result != NULL){
			node_t *tmp_node = container->head_result;
			container->head_result = container->head_result->next;
			free(tmp_node->id);/* free all filename qui*/
			free(tmp_node);
		}
		// if(pthread_mutex_destroy(&container->mtx) != 0){
		// 	perror("mutex destroy");
		// 	break;
		// }

		free(container);
		return 0;

	}while(false);
	return -1;
}

void free_node(node_t *node){
	free(node->id);
	free(node);
}

/**
 * add un new_result nel container.
 * 
 * @param container dove memorizzare i results
 * @param new_result da aggiungere
 * @param new_filepath da aggiungere
 * 
 * @return 0 On successo, return -1 On error.
 */
int add_id(container_t *container, int priority, char *new_id){
	do{
		if(!container || !new_id) break;
		/* inizialliza*/
		node_t *new_node = calloc(sizeof(node_t), 1);
		if(!new_node) break;
		new_node->priority = priority;
		new_node->id = new_id;
		new_node->next = NULL;

		/* start insert nel linktable*/
		//LOCK_RETURN(&container->mtx, -1);
		node_t *prev = NULL;
		node_t *corrent = container->head_result;
		while(corrent != NULL && priority < corrent->priority){
			prev = corrent;
			corrent = corrent->next;
		}
		if(prev != NULL){
			prev->next = new_node;
			new_node->next = corrent;
		}
		else{/* vuota o il piu piccolo numero*/
			new_node->next = container->head_result;
			container->head_result = new_node;
		}
		//UNLOCK_RETURN(&container->mtx, -1);

		/* print result dopo add*/
		//print_results(container);

		return 0;
	}while(false);

	return -1;
}

void* remove_id(container_t *container, char *id, int len){
	if(!container || !id) return NULL;
	if(strncmp(container->head_result->id, id, len) == 0){
		node_t *tmp_node = container->head_result;
		container->head_result = container->head_result->next;
		//return tmp_node;
		free_node(tmp_node);
	}
	else{
		node_t *prev = NULL;
		node_t *corrent = container->head_result;
		while(corrent != NULL && strncmp(corrent->id, id, len) != 0){
			//fprintf(stdout, "%s\n", corrent->filepath);
			prev = corrent;
			corrent = corrent->next;
		}
		if(corrent != NULL){//////////////////debug
			prev->next = corrent->next;
			//return corrent;
			free_node(corrent);
		}
	}
	return NULL;
}

/**
 * remove un new_result nel container.
 * 
 * @param container dove memorizzare i results
 * @param new_filepath da cancellare
 * 
 * @return 0 On successo, return -1 On error.
 */
node_t* remove_node(container_t *container, node_t *node, int len){
	if(!container || !node) return NULL;
	if(strncmp(container->head_result->id, node->id, len) == 0){
		node_t *tmp_node = container->head_result;
		container->head_result = container->head_result->next;
		//return tmp_node;
		free_node(tmp_node);
	}
	else{
		node_t *prev = NULL;
		node_t *corrent = container->head_result;
		while(corrent != NULL && strncmp(corrent->id, node->id, len) != 0){
			//fprintf(stdout, "%s\n", corrent->filepath);
			prev = corrent;
			corrent = corrent->next;
		}
		if(corrent != NULL){//////////////////debug
			prev->next = corrent->next;
			//return corrent;
			free_node(corrent);
		}
	}
	return NULL;
}

// node_t* add_node(container_t *container, node_t *node){
// 	do{
// 		if(!container || !node) break;

// 		/* start insert nel linktable*/
// 		//LOCK_RETURN(&container->mtx, -1);
// 		node_t *prev = NULL;
// 		node_t *corrent = container->head_result;
// 		while(corrent != NULL && node->priority < corrent->priority){
// 			prev = corrent;
// 			corrent = corrent->next;
// 		}
// 		if(prev != NULL){
// 			prev->next = node;
// 			node->next = corrent;
// 		}
// 		else{/* vuota o il piu piccolo numero*/
// 			node->next = container->head_result;
// 			container->head_result = node;
// 		}
// 		//UNLOCK_RETURN(&container->mtx, -1);

// 		/* print result dopo add*/
// 		//print_results(container);

// 		return 0;
// 	}while(false);

// 	return NULL;
// }

/**
 * stampa i risultati, va bene non acquisire mutex, tollerare alcune 
 * imprecisioni per le prestazioni.
 * 
 * @param container dove memorizzare i results
 * 
 * @return 0 On successo, return -1 On error.
 */
int print_results(container_t *container){
	if(!container) return -1;

	//system("clear"); /* svuota la scherma*/
	//printf("------------------results------------------------\n");
	node_t *tmp_node = container->head_result;
	while(tmp_node != NULL){
		fprintf(stdout, "%s\n", (char*)tmp_node->id);
		tmp_node = tmp_node->next;
	}
	return 0;
}
