#include<stdio.h>
#include<stdlib.h>
#include<sys/types.h>
#include<sys/stat.h>
#include<fcntl.h>
#include<unistd.h>
#include<string.h>

#ifndef BUFSIZE
#define BUFSIZE 256
#endif
#ifndef FILEIN
#define FILEIN "mycp_std.c"
#endif
#ifndef FILEOUT
#define FILEOUT "mycp_std_coppia.txt"
#endif

#define EXIT_F(m)						\
		perror(m); exit(EXIT_FAILURE);			
#define EC_MINUS1(s,m)	\
		if(s == -1) {perror(m); exit(EXIT_FAILURE);}
#define EC_NULL(s,m)	\
		if(s == NULL) {perror(m); exit(EXIT_FAILURE);}

int isNumber(const char *s){
	char* e = NULL;
	long val = strtol(s,&e,0);
	if(e != NULL && *e == (char)0) return val;
	return -1;
}
int main(int argc, char const *argv[])
{
	//if(argc != 4) {EXIT_F(argv[0]);}
	char *filein = NULL, *fileout = NULL;
	long bufsize = 0;
	if(argc == 4){
		filein = strndup(argv[1], strlen(argv[1]));
		fileout = strndup(argv[2], strlen(argv[2]));
		EC_MINUS1((bufsize = isNumber(argv[3])), "[num]");
	}
	else{
		filein = strndup(FILEIN, strlen(FILEIN));
		fileout = strndup(FILEOUT, strlen(FILEOUT));
		bufsize = BUFSIZE;
	}
	FILE *fdin = NULL, *fdout = NULL;
	char* buf = NULL;
	EC_NULL((fdin = fopen(filein, "r")), "opening fdin");
	EC_NULL((fdout = fopen(fileout, "w")), "opening fdout");
	EC_NULL((buf = (char*)malloc(sizeof(char) * bufsize)), "malloc:buf");
	
	while((fgets(buf, bufsize, fdin)) != NULL){
		fprintf(fdout, "%s", buf);
		// fwrite(buf, sizeof(char), strlen(buf), fdout);
	}

	free(filein);
	free(fileout);
	fclose(fdin);
	fclose(fdout);
	free(buf);
	return 0;
}