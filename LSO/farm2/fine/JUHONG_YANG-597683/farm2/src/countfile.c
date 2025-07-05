#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sys/uio.h>

#include <utils.h>
#include <countfile.h>

/**
 * funzione per calcoare il risultato.
 * 
 * @param arg puntaore a una struttura countfile_t
 */
void *countfile(void *arg){
	countfile_t *cf = (countfile_t*)arg;
	pthread_mutex_t *mtx_sock = cf->mtx_sock;
	char *filepath = cf->filepath;
	long filesize = cf->filesize;
	long len_filepath = cf->len_filepath;
	int ssock = cf->ssock;

	FILE* fin = fopen(filepath, "rb");
	if(!fin){
		perror("fopen");
		if(filepath) free(filepath);
		if(cf) free(cf);
		return (void*)NULL;
	}

	long nread = filesize / 8; /* ogni long codificato con 8 bytes*/
	long val, result = 0;
	for (long i = 0; i < nread; ++i)
	{
		fread(&val, sizeof(long), 1, fin);
		result += val * i;
	}

	int notused;
	/* lock la socket sta usando*/
	LOCK(mtx_sock);
	SYSCALL_EXIT(notused, writen(ssock, &result, sizeof(long)), "write");
	SYSCALL_EXIT(notused, writen(ssock, &len_filepath, sizeof(long)), "write");
	SYSCALL_EXIT(notused, writen(ssock, filepath, strlen(filepath)), "write");

	// struct iovec iov[3];
	// iov[0].iov_base = &result; iov[0].iov_len = sizeof(long);
	// iov[1].iov_base = &len_filepath; iov[1].iov_len = sizeof(long);
	// iov[2].iov_base = filepath; iov[2].iov_len = strlen(filepath);
	// SYSCALL_EXIT(notused, writevn(ssock, iov, 3), "writev");

	UNLOCK(mtx_sock);

	if(cf->filepath) free(cf->filepath);
	if(cf) free(cf);
	fclose(fin);

	return (void*)NULL;
}
