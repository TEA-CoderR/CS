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
//#define EC_NULL(e,c,m)    \
//        if((e = c) == NULL) {errno = e, perror(m); exit(errno);}
#define EC_NULL(s,m)    \
	if(s == NULL) {perror(m); exit(EXIT_FAILURE);}


char* read_cmdline(char *buf){
	fprintf(stdout, ">");
	if(fgets(buf, N, stdin) == NULL) EXIT_F("fgets");
	buf[strlen(buf)] = '\0';
	return buf;
}
int main(int argc, char const *argv[])
{
	int ssock, csock;
	/*simblo di error*/
	int e;
	/* Initialze sockaddr*/
	struct sockaddr_un sa;
	memset(&sa, '0', sizeof(sa));
	strncpy(sa.sun_path, SOCKETNAME, UNIX_PATH_MAX);
	sa.sun_family = AF_UNIX;
	/* fork a process client*/
	int pid1, pid2;
	EC_MINUS1(pid1, fork(), "fork");
	if(pid1){// server
		/* create pipe and alloc buffer*/
		int pfd[2], frombc[2];
		char *buf;
		EC_NULL((buf = calloc(sizeof(char), N)), "calloc");
		EC_MINUS1(e, pipe(pfd), "pipe");
		EC_MINUS1(e, pipe(frombc), "pipe");
		/* configure server*/
		EC_MINUS1(ssock, socket(AF_UNIX, SOCK_STREAM, 0), "socket");
		EC_MINUS1(e, bind(ssock, (struct sockaddr*)&sa, sizeof(sa)), "bind");
		EC_MINUS1(e, listen(ssock, SOMAXCONN), "listen");
		while(1){
			fprintf(stdout, "I'm server \n");
			//EC_MINUS1(csock, accept(ssock, NULL, 0), "accept");
			while((csock = accept(ssock, NULL, 0)) == -1);
			/* fork a process /usr/bin/bc deal with request*/
			EC_MINUS1(pid2, fork(), "fork");
			if(pid2 == 0){
				EC_MINUS1(e, dup2(pfd[0], 0), "dup2");
				EC_MINUS1(e, dup2(frombc[1], 1), "dup2");
				close(pfd[0]);
				close(pfd[1]);
				close(frombc[0]);
				close(frombc[1]);
				execl("/usr/bin/bc", "bc", "-lq", NULL);
				EXIT_F("exec");
			}
			close(pfd[0]);
			close(frombc[1]);
			while(1){
				/* read a request*/
				EC_MINUS1(e, read(csock, buf, N), "read");
				EC_MINUS1(e, write(pfd[1], buf, strlen(buf)), "write");
				if(!strncmp(buf, "quit", 4)) break;
				fprintf(stdout, "server received a request: %s\n", buf);
				EC_MINUS1(e, read(frombc[0], buf, N), "read");
				/* write result to client*/
				EC_MINUS1(e, write(csock, buf, strlen(buf)), "write");
			}

			EC_MINUS1(e, waitpid(pid2, NULL, 0), "waitpid");
			close(pfd[1]);
			close(frombc[0]);
		}
		
		EC_MINUS1(e, close(ssock), "close");
		EC_MINUS1(e, close(csock), "close");
		close(pfd[0]);
		close(pfd[1]);
		free(buf);
	}
	else{//client
		char *buf2;
		EC_NULL((buf2 = calloc(sizeof(char), N)), "calloc");
		/* configure client*/
		EC_MINUS1(ssock, socket(AF_UNIX, SOCK_STREAM, 0), "socket");
		while(connect(ssock, (struct sockaddr*)&sa, sizeof(sa)) == -1){
			if(errno = ENOENT) sleep(1);
			else exit(EXIT_FAILURE);
		}
		/* connected */
		while(1){
			char *s = read_cmdline(buf2);
			// fprintf(stdout, ">");
			// fgets(buf2, N, stdin);
			//EC_MINUS1(e, write(ssock, buf2, strlen(buf2)), "write");
			EC_MINUS1(e, write(ssock, s, strlen(s)), "write");
			if(!strncmp(s, "quit", 4)) break;
			EC_MINUS1(e, read(ssock, buf2, N), "read");
			fprintf(stdout, "client received a reply: %s\n", buf2);
		}

		EC_MINUS1(e, close(ssock), "close");
		free(buf2);
		exit(EXIT_SUCCESS);
	}
	
	EC_MINUS1(e, waitpid(pid1, NULL, 0), "waitpid");
	return 0;
}