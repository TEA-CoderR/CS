#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <errno.h>
#include <unistd.h>
#include <time.h>
#include <pwd.h>
#include <grp.h>

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


void pasring(char const *filename){
	struct stat info;
	EC_MINUS1((stat(filename, &info)), "stat");

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

	printf(" %ld", (long)info.st_ino);
	struct passwd *p = getpwuid(info.st_uid);
	struct group *g = getgrgid(info.st_gid);
	printf(" %s", p->pw_name);
	printf(" %s", g->gr_name);	

	printf(" %ld", (long)info.st_size);
	char *time = strndup(ctime(&info.st_mtime),strlen(ctime(&info.st_mtime)) - 1);
	printf(" %s ", time);
	printf("%s\n", filename);
	free(time);
}
int main(int argc, char const *argv[])
{
	if(argc < 2) {
		//EXIT_F("parameter error")
		DIR *dir = NULL;
		struct dirent *file = NULL;
		EC_NULL((dir = opendir(".")), "opendir");
		while((errno = 0, file = readdir(dir)) != NULL){
			pasring(file->d_name);
		}
		if(errno != 0) {EXIT_F("readdir");}
		EC_MINUS1((closedir(dir)), "closedir");

	}
	else{
		for (int i = 0; i < argc; ++i)
		{
			pasring(argv[i]);
		}
	}
	return 0;
}