#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

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

	int fdin;
	long *buf = NULL;
	do{
		if((fdin = open(filepath, O_RDONLY)) == -1){
			perror("FATAL ERROR open in countfile");
			break;
		}
		
		long nread = filesize / 8; /* ogni long codificato con 8 bytes*/
		buf = calloc(sizeof(long), nread + 1);
		if(read(fdin, buf, nread) == -1){
			perror("FATAL ERROR read in countfile");
			break;
		}

		long result = 0;
		for (long i = 0; i < nread; ++i)
		{
			result += buf[i] * i;
		}

		int notused;
		SYSCALL_EXIT(notused, writen(ssock, &result, sizeof(long)), "write");
		SYSCALL_EXIT(notused, writen(ssock, &len_filepath, sizeof(long)), "write");
		SYSCALL_EXIT(notused, writen(ssock, filepath, strlen(filepath)), "write");
	}while(0);

	if(cf->filepath) free(cf->filepath);
	if(cf) free(cf);
	if(buf) free(buf);
	if(fdin){
		if(close(fdin) == -1) perror("FATAL ERROR close in countfile");
	}

	return (void*)NULL;
}
