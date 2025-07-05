#include<stdio.h>
#include<stdlib.h>
#include<string.h>

#define FILENAME "/etc/passwd"
#define BUFFERSIZE 512
#define CHECK_PTR_EXIT(p, s)	\
	if(p == NULL){				\
		perror(s);				\
		exit(EXIT_FAILURE);		\
	}

int main(int argc, char const *argv[])
{
	if(argc != 2){
		perror(argv[0]);
		exit(EXIT_FAILURE);
	}
	FILE* fin = NULL;
	FILE* fout = NULL;
	CHECK_PTR_EXIT((fout = fopen(argv[1], "w")), "opening out.txt");
	CHECK_PTR_EXIT((fin = fopen(FILENAME, "r")), "opening in.txt");
	
	char* buf = (char*)malloc(sizeof(char) * BUFFERSIZE);
	while(!feof(fin)){
		fgets(buf, BUFFERSIZE, fin);
		int sizeN = strchr(buf, ':') - buf;
		char* tmp = strndup(buf, sizeN);
		fprintf(fout, "%s\n", tmp);
	}
	fclose(fout);
	fclose(fin);
	free(buf);
	return 0;
}