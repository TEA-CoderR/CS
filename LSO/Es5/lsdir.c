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

void stampaFiles(char *dirpath, char *subpath){
	DIR *dir = NULL;
	struct dirent *file = NULL;
	struct stat info;
	EC_NULL((dir = opendir(dirpath)), "opendir");
	while((errno = 0, file = readdir(dir)) != NULL){
		if(strcmp(".", file->d_name) && strcmp("..", file->d_name)){
			strcpy(subpath, dirpath);
			strcat(subpath, "/");
			strncat(subpath, file->d_name, strlen(file->d_name));
			EC_MINUS1((stat(subpath, &info)), subpath);
		}
		else{
			EC_MINUS1((stat(dirpath, &info)), "stat");
		}
		// printf("%s\n", file->d_name);
		// printf("%s\n", subpath);
		printf("%s\t", file->d_name);
		printf("%ld\t", (long)info.st_size);
		if(S_ISREG(info.st_mode)) printf("r");
		else if(S_ISDIR(info.st_mode)) printf("d");
		else if(S_ISLNK(info.st_mode)) printf("l");
		else if(S_ISCHR(info.st_mode)) printf("c");
		else if(S_ISBLK(info.st_mode)) printf("b");
		else if(S_ISFIFO(info.st_mode)) printf("p");
		else if(S_ISSOCK(info.st_mode)) printf("s");
		else printf("-");

		if(S_IRUSR & info.st_mode) printf("r");
		else printf("-");
		if(S_IWUSR & info.st_mode) printf("w");
		else printf("-");
		if(S_IXUSR & info.st_mode) printf("x");
		else printf("-");

		if(S_IRGRP & info.st_mode) printf("r");
		else printf("-");
		if(S_IWGRP & info.st_mode) printf("w");
		else printf("-");
		if(S_IXGRP & info.st_mode) printf("x");
		else printf("-");

		if(S_IROTH & info.st_mode) printf("r");
		else printf("-");
		if(S_IWOTH & info.st_mode) printf("w");
		else printf("-");
		if(S_IXOTH & info.st_mode) printf("x");
		else printf("-");
		printf("\n");
	}
	if(errno != 0) {EXIT_F("readdir");}
	EC_MINUS1((closedir(dir)), "closedir");
}

void stampa(const char *dirpath, char *dirname, char *subdir, char *buf){
	struct stat info;
	EC_MINUS1((stat(dirpath, &info)), "stat");
	printf("Directory: <%s>\n", dirname);
	//stampaFiles(dirpath, buf);
	printf("---------------------------\n");
	DIR *dir = NULL;
	struct dirent *file = NULL;
	EC_NULL((dir = opendir(dirpath)), "opendir");
	while((errno = 0, file = readdir(dir)) != NULL){
		strncpy(buf, dirpath, N - 1);
		strncat(buf, "/", N - 1);
		strncat(buf, file->d_name, N - 1);
		EC_MINUS1((stat(buf, &info)), "stat");
		if(S_ISDIR(info.st_mode)){
			strcpy(subdir, buf);
			if(buf[strlen(buf) - 1] == '.') continue;
			stampa(subdir, file->d_name, subdir, buf);
		}{
			printf("%s\t", file->d_name);
			printf("%ld\t", (long)info.st_size);
			if(S_ISREG(info.st_mode)) printf("r");
			else if(S_ISDIR(info.st_mode)) printf("d");
			else if(S_ISLNK(info.st_mode)) printf("l");
			else if(S_ISCHR(info.st_mode)) printf("c");
			else if(S_ISBLK(info.st_mode)) printf("b");
			else if(S_ISFIFO(info.st_mode)) printf("p");
			else if(S_ISSOCK(info.st_mode)) printf("s");
			else printf("-");

			if(S_IRUSR & info.st_mode) printf("r");
			else printf("-");
			if(S_IWUSR & info.st_mode) printf("w");
			else printf("-");
			if(S_IXUSR & info.st_mode) printf("x");
			else printf("-");

			if(S_IRGRP & info.st_mode) printf("r");
			else printf("-");
			if(S_IWGRP & info.st_mode) printf("w");
			else printf("-");
			if(S_IXGRP & info.st_mode) printf("x");
			else printf("-");

			if(S_IROTH & info.st_mode) printf("r");
			else printf("-");
			if(S_IWOTH & info.st_mode) printf("w");
			else printf("-");
			if(S_IXOTH & info.st_mode) printf("x");
			else printf("-");
			printf("\n");
		}
	}
	if(errno != 0) {EXIT_F("readdir");}
	if(closedir(dir) != 0) return;
}

void stampa1(char *dirpath){
	struct stat info;
	EC_MINUS1((stat(dirpath, &info)), "stat");
	printf("Directory: <%s>\n", dirpath);
	//stampaFiles(dirpath, buf);
	printf("---------------------------\n");
	DIR *dir = NULL;
	struct dirent *file = NULL;
	char buf[N];	
	EC_NULL((dir = opendir(dirpath)), "opendir");
	while((errno = 0, file = readdir(dir)) != NULL){
		strncpy(buf, dirpath, N - 1);
		strncat(buf, "/", N - 1);
		strncat(buf, file->d_name, N - 1);
		EC_MINUS1((stat(buf, &info)), "stat");
		if(S_ISDIR(info.st_mode)){
			//strcpy(subdir, buf);
			if(buf[strlen(buf) - 1] == '.') continue;
			stampa1(buf);
		}{
			printf("%s\t", file->d_name);
			printf("%ld\t", (long)info.st_size);
			if(S_ISREG(info.st_mode)) printf("r");
			else if(S_ISDIR(info.st_mode)) printf("d");
			else if(S_ISLNK(info.st_mode)) printf("l");
			else if(S_ISCHR(info.st_mode)) printf("c");
			else if(S_ISBLK(info.st_mode)) printf("b");
			else if(S_ISFIFO(info.st_mode)) printf("p");
			else if(S_ISSOCK(info.st_mode)) printf("s");
			else printf("-");

			if(S_IRUSR & info.st_mode) printf("r");
			else printf("-");
			if(S_IWUSR & info.st_mode) printf("w");
			else printf("-");
			if(S_IXUSR & info.st_mode) printf("x");
			else printf("-");

			if(S_IRGRP & info.st_mode) printf("r");
			else printf("-");
			if(S_IWGRP & info.st_mode) printf("w");
			else printf("-");
			if(S_IXGRP & info.st_mode) printf("x");
			else printf("-");

			if(S_IROTH & info.st_mode) printf("r");
			else printf("-");
			if(S_IWOTH & info.st_mode) printf("w");
			else printf("-");
			if(S_IXOTH & info.st_mode) printf("x");
			else printf("-");
			printf("\n");
		}
	}
	if(errno != 0) {EXIT_F("readdir");}
	if(closedir(dir) != 0) return;
}

void initialize(char **dirname, int argc, char const *argv[]){
	if(argc != 2){
		printf("Usage :%s <dirname>, use default argment now\n",argv[0]);
		*dirname = strndup(DIRNAME, strlen(DIRNAME));
	}
	else *dirname = strndup(argv[1], strlen(argv[1]));
}

void lsR(char *dirpath){
	struct stat info;
	EC_MINUS1((stat(dirpath, &info)), "stat");

	DIR *dir;
	struct dirent *file = NULL;
	char buf[N];
	printf("Directory: <%s>\n", dirpath);
	printf("---------------------------\n");
	EC_NULL((dir = opendir(dirpath)), "opendir");
	while((errno = 0, file = readdir(dir)) != NULL){
		// if(!strcmp("..", file->d_name)) continue;
		// if(!strcmp(".", file->d_name)) continue;
		//if(!strcmp(".", file->d_name) || !strcmp("..", file->d_name)) continue;
		strncpy(buf, dirpath, N - 1);
		strncat(buf, "/", N - 1);
		strncat(buf, file->d_name, N - 1);
		EC_MINUS1((stat(buf, &info)), "stat");
		if(S_ISDIR(info.st_mode)){
			//strcpy(subdir, buf);
			if(buf[strlen(buf) - 1] == '.') continue;
			lsR(buf);
		}
		else{
			printf("%s\t", file->d_name);
			printf("%ld\t", (long)info.st_size);
			if(S_ISREG(info.st_mode)) printf("r");
			else if(S_ISDIR(info.st_mode)) printf("d");
			else if(S_ISLNK(info.st_mode)) printf("l");
			else if(S_ISCHR(info.st_mode)) printf("c");
			else if(S_ISBLK(info.st_mode)) printf("b");
			else if(S_ISFIFO(info.st_mode)) printf("p");
			else if(S_ISSOCK(info.st_mode)) printf("s");
			else printf("-");

			if(S_IRUSR & info.st_mode) printf("r");
			else printf("-");
			if(S_IWUSR & info.st_mode) printf("w");
			else printf("-");
			if(S_IXUSR & info.st_mode) printf("x");
			else printf("-");

			if(S_IRGRP & info.st_mode) printf("r");
			else printf("-");
			if(S_IWGRP & info.st_mode) printf("w");
			else printf("-");
			if(S_IXGRP & info.st_mode) printf("x");
			else printf("-");

			if(S_IROTH & info.st_mode) printf("r");
			else printf("-");
			if(S_IWOTH & info.st_mode) printf("w");
			else printf("-");
			if(S_IXOTH & info.st_mode) printf("x");
			else printf("-");
			printf("\n");
		}
	}
	if(errno != 0) {EXIT_F("readdir");}
	if(closedir(dir) != 0) return;
}

int main(int argc, char const *argv[])
{
	char *dirname = NULL;
	initialize(&dirname, argc, argv);

	// char *buf = NULL;
	// char *subdir = NULL;
	// EC_NULL((buf = (char*)malloc(sizeof(char) * N)), "malloc");
	// EC_NULL((subdir = (char*)malloc(sizeof(char) * N)), "malloc");

	//stampa1(dirname);
	//stampa(dirname, dirname, subdir, buf);
	lsR(dirname);
	free(dirname);
	return 0;
}