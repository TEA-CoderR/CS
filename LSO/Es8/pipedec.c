#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<unistd.h>
#include<sys/types.h>
#include<sys/wait.h>

#define N "10"
#define EXIT_F(m)                       \
        (perror(m), exit(EXIT_FAILURE));          
#define EC_MINUS1(s,m)  \
        if(s == -1) {perror(m); exit(EXIT_FAILURE);}
#define EC_NULL(s,m)    \
        if(s == NULL) {perror(m); exit(EXIT_FAILURE);}

void cleanall(int *pfd, int *pfd2){
	close(pfd[0]);
	close(pfd[1]);
	close(pfd2[1]);
	close(pfd2[1]);
}
int main(int argc, char const *argv[])
{
	int pid1, pid2, pfd[2], pfd2[2];
	EC_MINUS1(pipe(pfd), "pipe");
	EC_MINUS1(pipe(pfd2), "pipe");
	EC_MINUS1((pid1 = fork()), "fork");
	if(pid1 == 0){
		EC_MINUS1(dup2(pfd[0], 0), "dup2");
		EC_MINUS1(dup2(pfd2[1], 1), "dup2");
		cleanall(pfd, pfd2);
		execl("./dec", "dec", N, NULL);
		EXIT_F("exec");
	}
	EC_MINUS1((pid2 = fork()), "fork");
	if(pid2 == 0){
		EC_MINUS1(dup2(pfd2[0], 0), "dup2");
		EC_MINUS1(dup2(pfd[1], 1), "dup2");
		cleanall(pfd, pfd2);
		execl("./dec", "dec", NULL);
		EXIT_F("exec");
	}
	cleanall(pfd, pfd2);
	printf("%d lanciato un processo %d\n", getpid(), pid1);
	printf("%d anciato un processo %d\n",getpid(), pid2);
	waitpid(pid1, NULL, 0);
	waitpid(pid2, NULL, 0);
	return 0;
}