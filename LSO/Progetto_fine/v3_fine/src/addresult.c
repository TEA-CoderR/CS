#include <stdlib.h>
#include <unistd.h>
#include <sys/uio.h>

#include <addresult.h>
//#include <container.h>
#include <utils.h>

#ifndef MAX_FILENAME_LEN
#define MAX_FILENAME_LEN 255
#endif

/**
 * e' una funzione di ricevere i risultati di calcolo e mettere nel contianer
 */
// void *addresult(void *arg){
// 	addresult_t *ar = (addresult_t*)arg;
// 	int csock = *(ar->csock);
// 	int fd1_request_pipe = ar->fd1_request_pipe;
// 	container_t *container = ar->container;

// 	long result, len_filepath;
// 	char *filepath = NULL;
// 	int nread, notused, end = -1;

// 	do{
// 		/* read result*/
// 		SYSCALL_EXIT(nread, readn(csock, &result, sizeof(long)), "readn");
// 		if(nread == 0){/* connesione chiusa*/
// 			/* notifica master_collector c'e una connessione gia chiusa*/
// 			SYSCALL_EXIT(notused, writen(fd1_request_pipe, &end, sizeof(int)), "write");
// 			break;
// 		}

// 		/* read len_filepath*/
// 		SYSCALL_EXIT(nread, readn(csock, &len_filepath, sizeof(long)), "readn");

// 		filepath = calloc(sizeof(char), len_filepath + 1);
// 		if(!filepath) break;
// 		/* read filepath*/
// 		SYSCALL_EXIT(nread, readn(csock, filepath, len_filepath), "readn");
// 		filepath[nread] = '\0';

// 		/* add to container*/
// 		add_result(container, result, filepath);

// 		/* notifica master_collector c'e ancora request di client*/
// 		SYSCALL_EXIT(notused, writen(fd1_request_pipe, &csock, sizeof(int)), "write");
// 	}while(0);

// 	if(ar->csock) free(ar->csock);
// 	if(ar) free(ar);
// 	return (void*)NULL;
// }

/**versione readvn
 * e' una funzione di ricevere i risultati di calcolo e mettere nel contianer
 */
void *addresult(void *arg){
	addresult_t *ar = (addresult_t*)arg;
	int csock = *(ar->csock);
	int fd1_request_pipe = ar->fd1_request_pipe;
	container_t *container = ar->container;

	char *filepath = NULL;
	long result, len_filepath;
	int nread, notused, end = -1;
	do{
		filepath = calloc(sizeof(char), MAX_FILENAME_LEN);
		if(!filepath) break;

		struct iovec iov[3];
		iov[0].iov_base = &result; iov[0].iov_len = sizeof(long);
		iov[1].iov_base = &len_filepath; iov[1].iov_len = sizeof(long);
		iov[2].iov_base = filepath; iov[2].iov_len = MAX_FILENAME_LEN;

		/* read result*/
		SYSCALL_EXIT(nread, readvn(csock, iov, 3), "readv");
		if(nread == 0){/* connesione chiusa*/
			if(filepath) free(filepath);
			/* notifica master_collector c'e una connessione gia chiusa*/
			SYSCALL_EXIT(notused, writen(fd1_request_pipe, &end, sizeof(int)), "write");
			break;
		}

		/* riduce la memoria allocata in heap*/
		if(len_filepath * 2 < MAX_FILENAME_LEN){
			filepath = realloc(filepath, len_filepath + 1);
			if(!filepath) break;
		}
		filepath[len_filepath] = '\0';

		/* add to container*/
		add_result(container, result, filepath);

		/* notifica master_collector c'e ancora request di client*/
		SYSCALL_EXIT(notused, writen(fd1_request_pipe, &csock, sizeof(int)), "write");
	}while(0);

	if(ar->csock) free(ar->csock);
	if(ar) free(ar);
	return (void*)NULL;
}