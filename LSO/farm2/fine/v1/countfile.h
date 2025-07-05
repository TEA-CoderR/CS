#ifndef COUNTFILE_H_
#define COUNTFILE_H_

typedef struct countfile_s{
	char *filepath;
	long filesize;
	long len_filepath;
	int ssock;
}countfile_t;

/**
 * funzione per calcoare il risultato.
 * 
 * @param arg puntaore a una struttura countfile_t
 */
void *countfile(void *arg);

#endif