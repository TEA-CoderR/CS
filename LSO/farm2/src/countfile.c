

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>

#include <utils.h>
#include <countfile.h>

/**
 * funzione per calcoare il risultato.
 * 
 * @param arg puntaore a una struttura countfile_t
 */
void *countfile(void *arg){
	countfile_t *cf = (countfile_t*)arg;
	char *filepath = cf->filepath;
	long filesize = cf->filesize;
	long len_filepath = cf->len_filepath;
	int ssock = cf->ssock;

	FILE* fin = fopen(filepath, "rb");
	if(!fin){
		perror("fopen");
		if(filepath) free(filepath);
		fprintf(stderr, "un countfile exit\n");
		return (void*)NULL;
	}

	// /* inizialliza msg*/
	// msg_t msg;
	// msg.result = 0;
	// msg.filename = filename;

	long nread = filesize / 8; /* ogni long codificato con 8 bytes*/
	long val, result = 0;
	for (long i = 0; i < nread; ++i)
	{
		fread(&val, sizeof(long), 1, fin);
		result += val * i;
	}

	int notused;
	/* inizia inviare msg*/
	//long ack = 1; /* invia una identifatore alive*/
	//SYSCALL_EXIT(notused, writen(ssock, &ack, sizeof(long)), "write");
	//SYSCALL_EXIT(notused, writen(ssock, &msg, sizeof(msg_t)), "write");
	SYSCALL_EXIT(notused, writen(ssock, &result, sizeof(long)), "write");
	SYSCALL_EXIT(notused, writen(ssock, &len_filepath, sizeof(long)), "write");
	SYSCALL_EXIT(notused, writen(ssock, filepath, strlen(filepath)), "write");

	if(cf->filepath) free(cf->filepath);
	if(cf) free(cf);
	fclose(fin);

	return (void*)NULL;
}
