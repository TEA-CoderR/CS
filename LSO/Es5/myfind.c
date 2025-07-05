#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <errno.h>
#include <unistd.h>

#ifndef DIRNAME
#define DIRNAME "."
#endif
#ifndef FILENAME
#define FILENAME "./myfind.c"
#endif
#define N 256

#define EXIT_F(m)						\
		perror(m); exit(EXIT_FAILURE);			
#define EC_MINUS1(s,m)	\
		if(s == -1) {perror(m); exit(EXIT_FAILURE);}
#define EC_NULL(s,m)	\
		if(s == NULL) {perror(m); exit(EXIT_FAILURE);}

int findFile(char *dirname, char *filename, char *subdir, char *buf){
	DIR *dir = NULL;
	struct dirent *file = NULL;
	struct stat info; 
	EC_NULL((dir = opendir(dirname)), "opendir");
	//printf("%s\n", dirname);
	while((errno = 0, file = readdir(dir)) != NULL){
		//if(!strcmp("..", file->d_name)) continue;
		//if(!strcmp(".", file->d_name)) continue;
		strcpy(buf, dirname);
		strcat(buf, "/");
		strncat(buf, file->d_name, strlen(file->d_name));
		 if(!strcmp(filename, buf)){
			printf("%s\n", buf);
			EC_MINUS1((closedir(dir)), "closedir");
			return 0;
		}
		printf("%s\n", buf);
		EC_MINUS1((stat(buf, &info)), "stat");
		if(S_ISDIR(info.st_mode)){
			strcpy(subdir, buf);
			if(buf[strlen(buf) - 1] == '.') continue;
			if((findFile(subdir, filename, subdir, buf)) == 0){;//ricorsive
				EC_MINUS1((closedir(dir)), "closedir");
				return 1;
			}
		}
	}
	if(errno != 0) {EXIT_F("readdir");}

	EC_MINUS1((closedir(dir)), "closedir");

	return -1;
}

void initialize(char **dirname, char **filename, int argc, char const *argv[]){
	if(argc < 3){
		*dirname = strndup(DIRNAME, strlen(DIRNAME)); 
		*filename = strndup(FILENAME, strlen(FILENAME)); 
	}
	else {
		*dirname = strndup(argv[1], strlen(argv[1])); 
		*filename = strndup(argv[2], strlen(argv[2]));
	}
}
int main(int argc, char const *argv[])
{
	char *dirname = NULL, *filename = NULL; 
	initialize(&dirname, &filename, argc, argv);

	char *buf = NULL, *subdir = NULL;
	EC_NULL((buf = (char*)malloc(sizeof(char) * N)), "malloc");
	EC_NULL((subdir = (char*)malloc(sizeof(char) * N)), "malloc");
	if((findFile(dirname, filename, subdir, buf)) == -1) printf("%s :non exit this file\n", filename);
	
	free(buf);
	free(subdir);
	free(dirname);
	free(filename);
	return 0;
}
