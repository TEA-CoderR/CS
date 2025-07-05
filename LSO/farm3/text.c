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
#include<ctype.h>
#include <pthread.h>
#include<signal.h>
#include <sys/select.h>

#include "threadpool.h"
#include "utils.h"

#define SOCKETNAME "./mysoc"

#define EC_MINUS1(e,c,m)  \
	if((e = c) == -1) {errno = e, perror(m); exit(errno);}

volatile sig_atomic_t closeflag = 0;

void *fun(void *arg){
	int fd = *(int*)arg;
	printf("funread fd :%d\n", fd);
	int nread, n;
	EC_MINUS1(nread, read(fd, &n, sizeof(int)), "read");
	if(nread == 0){
		printf("111111111\n");
		pthread_exit(NULL);
		//FD_CLR(fd, &set);
		//close(fd);
		//continue;
	}
	if(n == -1) printf("222222222222222222222\n");

	return (void*)NULL;
}

void clean(){
	unlink(SOCKETNAME);
}
int e;
int main(int argc, char const *argv[])
{
	clean();
	atexit(clean);
	int ssock, csock;
	/* Initialze sockaddr*/
	struct sockaddr_un sa;
	strncpy(sa.sun_path, SOCKETNAME, strlen(SOCKETNAME) + 1);
	sa.sun_family = AF_UNIX;
	/* fork a process client*/
	int pid1;
	EC_MINUS1(pid1, fork(), "fork");
	if(pid1){// server
		threadpool_t *pool = threadpool_create(4, 8, NULL);
		/* configure server*/
		EC_MINUS1(ssock, socket(AF_UNIX, SOCK_STREAM, 0), "socket");
		EC_MINUS1(e, bind(ssock, (struct sockaddr*)&sa, sizeof(sa)), "bind");
		EC_MINUS1(e, listen(ssock, SOMAXCONN), "listen");

		fd_set set, tmpset;
		int fd_num;
		fd_num = ssock;
		FD_ZERO(&set);
		FD_SET(ssock, &set);
		while(1){
			/* initialze rdset*/
			tmpset = set;
			//EC_MINUS1(e, select(fd_num + 1, &rdset, NULL, NULL, NULL), "select");
			if(select(fd_num + 1, &tmpset, NULL, NULL, NULL) == -1){
				perror("select");
			}
			else{
				for (int fd = 0; fd <= fd_num; ++fd)
				{
					if(FD_ISSET(fd, &tmpset)){
						if(fd == ssock){/* accept pronto*/
							//EC_MINUS1(csock, accept(ssock, NULL, 0), "accept");
							if((csock = accept(ssock, NULL, 0)) == -1){
								if(errno = EINTR){
								}
								else{
									perror("accept");
									//r = EXIT_FAILURE
								}
							}
							//EC_MINUS1(csock, accept(ssock, NULL, 0), "accept");
							//printf("accept fd:%d\n", csock);
							FD_SET(csock, &set);
							if(csock >fd_num) fd_num = csock;
						}
						else{ /*Sock I/O*/
							int *csock = calloc(sizeof(int), 1);
							*csock = fd;
							add_task(pool, fun, csock);
							printf("add un I/O task fd:%d %p\n", *csock, csock);
							//FD_CLR(fd, &set);
						}
					}
				}
			}
		}
	}
	else{//client
		int ssock[4];
		for (int i = 0; i < 4; ++i)
		{
			EC_MINUS1(ssock[i], socket(AF_UNIX, SOCK_STREAM, 0), "socket");
			while(connect(ssock[i], (struct sockaddr*)&sa, sizeof(sa)) == -1){
				if(errno = ENOENT) sleep(1);
				else exit(EXIT_FAILURE);
			}
			//printf("connected fd:%d\n", ssock[i]);
		}
		int n = -1;
		for (int i = 0; i < 4; ++i)
		{
			write(ssock[i], &n, sizeof(int));
		}
		sleep(1);
		for (int i = 0; i < 4; ++i)
		{
			close(ssock[i]);
			//printf("closed fd:%d\n", ssock[i]);
		}
		
		exit(EXIT_SUCCESS);
	}
	return 0;
}
