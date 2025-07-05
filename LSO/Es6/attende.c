#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<unistd.h>
#include<sys/types.h>
#include<sys/wait.h>

#ifndef X
#define X "3"
#endif	
#define EXIT_F(m)						\
		perror(m); exit(EXIT_FAILURE);			
#define EC_MINUS1(s,m)	\
		if(s == -1) {perror(m); exit(EXIT_FAILURE);}
#define EC_NULL(s,m)	\
		if(s == NULL) {perror(m); exit(EXIT_FAILURE);}

void attende(char* x){
	char *argv[20];
	int pid;
	switch(pid = fork()){
	case -1:{
		printf("Cannot fork\n");
		break;
	}
	case 0:{
		// size_t len;
		// len = strlen("/bin/sleep") + 1;
		// EC_NULL((argv[0] = (char*)malloc(sizeof(char) * len)), "malloc");
		// strncpy(argv[0], "/bin/sleep", len);

		// len = strlen(X) + 1;
		// EC_NULL((argv[1] = (char*)malloc(sizeof(char) * len)), "malloc");
		// strncpy(argv[1], X, len);

		// argv[2] = NULL;
		// execvp(argv[0], &argv[0]);
		execl("/bin/sleep", "/bin/sleep", X, NULL);
		EXIT_F("exec");
	}
	default:{
		waitpid(pid, NULL, 0);
		printf("pid :%d ", getpid());
		printf("ppid :%d\n", getppid());
		// free(argv[0]);
		// free(argv[1]);
	}
}
}
int main(void)
{
	attende(X);
	return 0;
}