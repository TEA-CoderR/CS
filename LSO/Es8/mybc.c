#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<unistd.h>
#include<sys/types.h>
#include<sys/wait.h>


#define N 256
#define EXIT_F(m)                       \
        (perror(m), exit(EXIT_FAILURE));          
#define EC_MINUS1(s,m)  \
        if(s == -1) {perror(m); exit(EXIT_FAILURE);}
#define EC_NULL(s,m)    \
        if(s == NULL) {perror(m); exit(EXIT_FAILURE);}


char* read_cmdline(char *buf, int *pfd){
	printf(">");
	if(fgets(buf, N, stdin) == NULL) EXIT_F("fgets");
	write(pfd[1], buf, strlen(buf));
	return buf;
}
int main(int argc, char const *argv[])
{
	int pfd[2], tmpfd;
	char *buf;
	EC_MINUS1((pipe(pfd)), "pipe");
	EC_NULL((buf = (char*)malloc(sizeof(char) * N)), "malloc");
	//close(pfd[0]);
	int pid;
	EC_MINUS1((pid = fork()), "fork");
	if(pid == 0){
		EC_MINUS1(dup2(pfd[0], 0), "dup2");
		close(pfd[0]);
		close(pfd[1]);
		execl("/usr/bin/bc", "bc", "-lq", NULL);
		EXIT_F("exec");
	}
	close(pfd[0]);
	while(1){
		char *s = read_cmdline(buf, pfd);
		if(!strncmp(s, "quit", 4)) break;
	}
	EC_MINUS1((waitpid(pid, NULL, 0)), "waitpid");
	//close(pfd[0]);
	close(pfd[1]);
	free(buf);
	return 0;
}
// int main(int argc, char const *argv[])
// {
// 	int pfd[2], tmpfd;
// 	char *buf;
// 	EC_MINUS1((pipe(pfd)), "pipe");
// 	EC_NULL((buf = (char*)malloc(sizeof(char) * N)), "malloc");
// 	EC_MINUS1((tmpfd = dup(0)), "dup");
// 	EC_MINUS1(dup2(pfd[0], 0), "dup2");
// 	while(1){
// 		//if(!strcmp(read_cmdline(buf, pfd), "exit")) break;
// 		// printf(">");
// 		// fflush(stdout);
// 		// if(read(tmpfd, buf, N) != -1){
// 		// 	int len = strlen(buf);
// 		// 	buf[len] = '\0';
// 		// 	write(pfd[1], buf, N);
// 		// }
// 		// else continue;
// 		int pid;
// 		EC_MINUS1((pid = fork()), "fork");
// 		if(pid == 0){
// 			// EC_MINUS1(dup2(pfd[0], 0), "dup2");
// 			close(pfd[0]);
// 			close(pfd[1]);
// 			execl("/usr/bin/bc", "/usr/bin/bc", "-lq", NULL);
// 			EXIT_F("exec");
// 		}
// 		printf(">");
// 		fflush(stdout);
// 		if(read(tmpfd, buf, N) != -1){
// 			//int len = strlen(buf);
// 			//buf[len] = '\0';
// 			write(pfd[1], buf, N);
// 		}
// 		EC_MINUS1((waitpid(pid, NULL, 0)), "waitpid");
// 		//EC_MINUS1(dup2(tmpfd, 0), "dup");
// 	}
// 	close(pfd[0]);
// 	close(pfd[1]);
// 	free(buf);
// 	return 0;
// }