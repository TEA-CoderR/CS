#include <stdlib.h>
#include <unistd.h>

#include <addresult.h>
//#include <container.h>
#include <utils.h>


/**
 * e' una funzione di ricevere i risultati di calcolo e mettere nel contianer
 */
void *addresult(void *arg){
	addresult_t *ar = (addresult_t*)arg;
	int csock = ar->csock;
	int fd1_request_pipe = ar->fd1_request_pipe;
	container_t *container = ar->container;
	//printf("addresult csock------%d\n", csock);

	long result, len_filepath;
	char *filepath = NULL;
	int nread, notused, end = -1;
	//printf("%d start add result from------%d\n", (unsigned int)pthread_self(), csock);
	/* read result*/
	SYSCALL_EXIT(nread, readn(csock, &result, sizeof(long)), "readn");
	if(nread == 0){/* connesione chiusa*/
		printf("%d never------%d\n", (unsigned int)pthread_self(), csock);
		/* notifica master_collector c'e una connessione gia chiusa*/
		SYSCALL_EXIT(notused, writen(fd1_request_pipe, &end, sizeof(int)), "write");
		//SYSCALL_EXIT(notused, close(csock), "close");///////////////////////////////////debug
		free(ar);
		pthread_exit(NULL);
	}
	//printf("addresult result------%ld\n", result);

	/* read len_filepath*/
	SYSCALL_EXIT(nread, readn(csock, &len_filepath, sizeof(long)), "readn");
	//printf("addresult len_filepath------%ld\n", len_filepath);

	filepath = calloc(sizeof(char), len_filepath);
	if(!filepath) EXIT_F("calloc");
	/* read filepath*/
	SYSCALL_EXIT(nread, readn(csock, filepath, len_filepath), "readn");
	//printf("addresult filepath------%s\n", filepath);
	//printf("%d riceve successo from------%d\n", (unsigned int)pthread_self(), csock);
	/* add to container*/
	add_result(container, result, filepath);
	//printf("%d addresult successo from------%d\n", (unsigned int)pthread_self(), csock);

	/* notifica master_collector c'e ancora request di client*/
	SYSCALL_EXIT(notused, writen(fd1_request_pipe, &csock, sizeof(int)), "write");

	free(ar);

	pthread_exit(NULL);
}