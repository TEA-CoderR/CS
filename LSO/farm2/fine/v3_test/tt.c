#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <pthread.h>
#include <sys/wait.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <signal.h>

#include "utils.h"
#include "master.h"
//#include "threadpool.h"
#include "countfile.h"


/**
 * rilasce la memoria di filename.
 * 
 * @param filename da rilasciare
 */
static void freememory(void *ptr){
	if(ptr) free(ptr);
}

/**
 * packing un task_arg.
 * 
 * @param cf puntatore task_arg
 * @param dirname puntatore a dir corrente
 * @param filename puntatore a file da contare
 * @param info del i_node file
 * @param ssock socket connessione aperta
 * @param mtx_sock mutex di socket
 * 
 * @return un puntatore cf On successo, return NULL On error.
 */
static countfile_t *packing_task_arg(char *dirname, char *filename, struct stat *info){
	long len_dirname = 0, len_delim = 0, len_filename = 0, len_filepath;
	if(dirname){
		len_dirname = strlen(dirname);
		len_delim = 1;
	}
	len_filename = strlen(filename);
	len_filepath = len_dirname + len_delim + len_filename;

	do{
		if(len_filepath > 255) break;/* filepath troppo lunguo*/

		/* combina filepath*/
		char *filepath = calloc(sizeof(char), len_filepath + 1);
		if(!filepath) break;
		printf("allocate %ld\n", len_filepath + 1);

		if(dirname){
			strncpy(filepath, dirname, len_filepath);
			strncat(filepath, "/", len_filepath);
			strncat(filepath, filename, len_filepath);
		}
		else strncpy(filepath, filename, len_filepath);

		if(stat(filepath, info) == -1) {
			freememory(filepath);
			printf("error-----------%s\n", filepath);
			perror("stat infofile"); 
			break;
		};

		/* alloca memoria*/
		countfile_t *cf = calloc(sizeof(countfile_t), 1);
		if(!cf){
			free(filepath);
			break;
		}
		printf("cf:%ld\n", sizeof(*cf));
		cf->filepath = filepath;
		cf->filesize = (long)info->st_size;
		cf->len_filepath = len_filepath;
		DEBUG(0,"input un file ");
		DEBUG(0,cf->filepath);
		return cf;
	}while(0);

	return NULL;
}

/**
 * parsing un dir, trova tutti i files nel dir in modo ricorsione, 
 * e aggiunge task nel pool.
 * 
 * @param pool puntatore al thread_pool
 * @param dirname da parsing
 * @param ssock array ai socket connessioni aperte
 * @mtx_sock array_mutex per i socket connessioni 
 * @param n_sock numero socket connessioni 
 * @param num_task numero del task
 * @param delay ritardo tra due add_task
 * 
 * @return 0 On successo, return 1 se pool e' chiuso, return -1 On error.
 */
static int parsing_dir(threadpool_t *pool, char *dirname){
	DIR *dir = NULL;
	struct dirent *file = NULL;
	struct stat info;
	if((dir = opendir(dirname)) == NULL){
		perror("opendir");
		return -1;
	}
	printf("1111111111\n");
	while((errno = 0, file = readdir(dir)) != NULL){
		printf("222222222222222222\n");
		/* ignora dir . e .. , riduce la allocazione memoria*/
		if(!strcmp(".", file->d_name) || !strcmp("..", file->d_name)) continue;

		printf("333333333333333333 %s\n", file->d_name);
		countfile_t *cf = NULL;
		if((cf = packing_task_arg(dirname, file->d_name, &info)) == NULL) return -1;/* On error*/

		if(S_ISDIR(info.st_mode)){
			int r = parsing_dir(pool, cf->filepath);
			free(cf->filepath);/* non serve piu'*/
			freememory(cf);
			if(r == -1) return -1;/* On error*/
			if(r == 1) return 1;/* pool gia' shutdown*/
		}
		else{/* e' un file*/
			int r = add_task(pool, countfile, cf);
			if(r == -1){
				freememory(cf->filepath);
				freememory(cf);
				return -1;/* On error*/
			}
			if(r == 1){
				freememory(cf->filepath);
				freememory(cf);
				return 1;/* pool gia' shutdown*/
			} 
		}
	}
	if(errno != 0) {perror("readdir"); return -1;}
	if(closedir(dir) != 0) {perror("closedir"); return -1;}

	return 0;
}

static int test_dir(char *dirname){
	DIR *dir = NULL;
	struct dirent *file = NULL;
	struct stat info;
	if((dir = opendir(dirname)) == NULL){
		perror("opendir");
		return -1;
	}
	printf("1111111111\n");
	while((errno = 0, file = readdir(dir)) != NULL){
		printf("222222222222222222\n");
		/* ignora dir . e .. , riduce la allocazione memoria*/
		if(!strcmp(".", file->d_name) || !strcmp("..", file->d_name)) continue;

		printf("333333333333333333 %s\n", file->d_name);
		// countfile_t *cf = NULL;
		// if((cf = packing_task_arg(dirname, file->d_name, &info)) == NULL) return -1;/* On error*/

		// if(S_ISDIR(info.st_mode)){
		// 	int r = test_dir(cf->filepath);
		// 	free(cf->filepath);/* non serve piu'*/
		// 	freememory(cf);
		// 	if(r == -1) return -1;/* On error*/
		// 	if(r == 1) return 1;/* pool gia' shutdown*/
		// }
	}
	if(errno != 0) {perror("readdir"); return -1;}
	if(closedir(dir) != 0) {perror("closedir"); return -1;}

	return 0;
}
int main(int argc, char const *argv[])
{
	//threadpool_t *pool = threadpool_create(4, 21, NULL);

	//parsing_dir(pool, "testdir");
	test_dir("testdir");
	//threadpool_destroy(pool);
	return 0;
}