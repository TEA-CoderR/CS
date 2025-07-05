#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<unistd.h>
#include<sys/types.h>
#include<sys/wait.h>
#include<sys/socket.h>
#include<sys/un.h>
#include<errno.h>
#include<time.h>

#define UNIX_PATH_MAX 108
#define SOCKETNAME "./mysocket"

#define N 256
#define EXIT_F(m)                       \
        (perror(m), exit(EXIT_FAILURE));          
#define EC_MINUS1(e,c,m)  \
        if((e = c) == -1) {errno = e, perror(m); exit(errno);}
// #define EC_NULL(s,m)    \
//         if(s == NULL) {perror(m); exit(EXIT_FAILURE);}
#define EC_NULL(e,c,m)    \
	if((e = c) == NULL) {errno = e, perror(m); exit(errno);}


char* read_cmdline(char *buf){
	printf(">");
	fflush(stdout);
	if(fgets(buf, N, stdin) == NULL) EXIT_F("fgets");
	return buf;
}
int main(int argc, char const *argv[])
{
	int ssock, csock;
	/* Initialze sockaddr*/
	struct sockaddr_un sa;
	strncpy(sa.sun_path, SOCKETNAME, UNIX_PATH_MAX);
	sa.sun_family = AF_UNIX;
	/* fork a process client*/
	int pid1, pid2;
	/*simblo di error*/
	int e;
	char *buf;
	//EC_NULL((buf = calloc(sizeof(char), N)), "calloc");
	EC_NULL(buf, calloc(sizeof(char), N), "calloc");
	EC_MINUS1(pid1, fork(), "fork");
	if(pid1){// server
		/* create pipe and alloc buffer*/
		//int pfd[2];
		// char *buf;
		//EC_MINUS1(e, pipe(pfd), "pipe");
		// EC_NULL(buf, calloc(sizeof(char), N), "calloc");
		/* configure server*/
		EC_MINUS1(ssock, socket(AF_UNIX, SOCK_STREAM, 0), "socket");
		EC_MINUS1(e, bind(ssock, (struct sockaddr*)&sa, sizeof(sa)), "bind");
		EC_MINUS1(e, listen(ssock, SOMAXCONN), "listen");
		//while(1){
			EC_MINUS1(csock, accept(ssock, NULL, 0), "accept");
			/* fork a process /usr/bin/bc deal with request*/
			// EC_MINUS1(pid2, fork(), "fork");
			// if(pid2 == 0){
			// 	EC_MINUS1(e, dup2(pfd[0], 0), "dup2");
			// 	EC_MINUS1(e, dup2(pfd[1], 1), "dup2");
			// 	close(pfd[0]);
			// 	close(pfd[1]);
			// 	execl("/usr/bin/bc", "bc", "-lq", NULL);
			// 	EXIT_F("exec");
			// }
			//while(1){
				/* read a request*/
				EC_MINUS1(e, read(csock, buf, N), "read");
				if(e == 0){
					printf("sleep\n");
					sleep(1);
					//continue;
				}
				printf("server %s\n", buf);
				//EC_MINUS1(e, write(pfd[1], buf, strlen(buf)), "write");
				//if(!strncmp(buf, "quit", 4)) break;
				if(strncmp(buf, "quit", 4)){
					fprintf(stdout, "server received a request: %s\n", buf);
					//EC_MINUS1(e, read(pfd[0], buf, N), "read");
					/* write result to client*/
					EC_MINUS1(e, write(csock, "bye!", 5), "write");
				}
				// fprintf(stdout, "server received a request: %s\n", buf);
				// EC_MINUS1(e, read(pfd[0], buf, N), "read");
				// /* write result to client*/
				// EC_MINUS1(e, write(csock, buf, strlen(buf)), "write");
			//}

			//EC_MINUS1(e, waitpid(pid2, NULL, 0), "waitpid");
		//}
		
		EC_MINUS1(e, close(ssock), "close");
		EC_MINUS1(e, close(csock), "close");
		// close(pfd[0]);
		// close(pfd[1]);
	}
	else{//client
		// char *buf2 = NULL;
		// EC_NULL(buf2, calloc(sizeof(char), N), "calloc");
		/* configure client*/
		EC_MINUS1(ssock, socket(AF_UNIX, SOCK_STREAM, 0), "socket");
		while(connect(ssock, (struct sockaddr*)&sa, sizeof(sa)) == -1){
			if(errno = ENOENT) sleep(1);
			else exit(EXIT_FAILURE);
		}
		/* connected */
		//while(1){
			//char *s = read_cmdline(buf2);
			//fprintf(stdout,"client %s\n", s);
			//fflush(stdout);
			EC_MINUS1(e, write(ssock, "hello!", 7), "write");
			//if(!strncmp(s, "quit", 4)) break;
			EC_MINUS1(e, read(ssock, buf, N), "read");
			fprintf(stdout, "client received a reply: %s\n", buf);
		//}

		EC_MINUS1(e, close(ssock), "close");
		exit(EXIT_SUCCESS);
	}
	EC_MINUS1(e, waitpid(pid1, NULL, 0), "waitpid");
	free(buf);
	return 0;
}