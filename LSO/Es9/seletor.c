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
#include<pthread.h>
#include<sys/select.h>

#define UNIX_PATH_MAX 108
#define SOCKETNAME "./myso"

#define N 256

#define EXIT_F(m)		\
	(perror(m), exit(EXIT_FAILURE));
#define EC_MINUS1(e,c,m)  \
	if((e = c) == -1) {errno = e, perror(m); exit(errno);}
#define EC_NULL(s,m)    \
	if(s == NULL) {perror(m); exit(EXIT_FAILURE);}
// #define CREATE(s,m)     \
// 	if(s != 0) {errno = s; perror(m); pthread_exit(errno);}
// #define JOIN(s,m)     \
// 	if(s != 0) {errno = s; perror(m); pthread_exit(errno);}

typedef struct targs{
	int tid;
	int csock;
}t_args;
typedef struct request{
	int rid;
	char *filename;
	struct sockaddr_un sa;
}t_request;

int update(int fd_max, fd_set *set);
static void run_server(struct sockaddr *psa);
static void* request(void *arg);

int main(int argc, char const *argv[])
{
	// int ssock, csock;
	/*simblo di error*/
	int e;
	/* Initialze sockaddr*/
	struct sockaddr_un sa;
	strncpy(sa.sun_path, SOCKETNAME, UNIX_PATH_MAX);
	sa.sun_family = AF_UNIX;
	/* fork a process client*/
	int pid1;
	EC_MINUS1(pid1, fork(), "fork");
	if(pid1){// server
		run_server((struct sockaddr*)&sa);
	}
	else{//client
		t_request *re = NULL;
		EC_NULL((re = calloc(sizeof(t_request), 1)), "calloc");
		pthread_t t;
		re->rid = 0;
		re->sa = sa;
		re->filename = "t1.txt";
		//CREATE(pthread_create(&t, NULL, &request, (void*)re), "pthread_create");
		pthread_create(&t, NULL, &request, (void*)re);

		t_request *re2 = NULL;
		EC_NULL((re2 = calloc(sizeof(t_request), 1)), "calloc");
		pthread_t t2;
		re2->rid = 1;
		re2->sa = sa;
		re2->filename = "t2.txt";
		// CREATE(pthread_create(&t2, NULL, &request, (void*)re2), "pthread_create");
		pthread_create(&t2, NULL, &request, (void*)re2);

		// JOIN(pthread_join(t, NULL), "pthread_join");
		// JOIN(pthread_join(t2, NULL), "pthread_join");
		pthread_join(t, NULL);
		pthread_join(t2, NULL);

		exit(EXIT_SUCCESS);
	}
	
	EC_MINUS1(e, waitpid(pid1, NULL, 0), "waitpid");
	return 0;
}
int update(int fd_max, fd_set *set){
	while(!FD_ISSET(--fd_max, set));
	return fd_max;
}
static void run_server(struct sockaddr *psa){
	/*simblo di error*/
	int e;
	int ssock, csock, fd_num = 0;
	char *buf = NULL;
	fd_set set, rdset;
	int nread;
	EC_NULL((buf = calloc(sizeof(char), N)), "calloc");
	EC_MINUS1(ssock, socket(AF_UNIX, SOCK_STREAM, 0), "socket");
	EC_MINUS1(e, bind(ssock, (struct sockaddr*)psa, sizeof(psa)), "bind");
	EC_MINUS1(e, listen(ssock, SOMAXCONN), "listen");
	if(ssock > fd_num) fd_num = ssock;
	FD_ZERO(&set);
	FD_SET(ssock, &set);
	while(1){
		/* initialze rdset*/
		rdset = set;
		//EC_MINUS1(e, select(fd_num + 1, &rdset, NULL, NULL, NULL), "select");
		if(select(fd_num + 1, &rdset, NULL, NULL, NULL) == -1){
			printf("select err -----------------------------\n");
			fflush(stdout);
			perror("select");
		}
		else{
			for (int fd = 0; fd <= fd_num; ++fd)
			{
				if(FD_ISSET(fd, &rdset)){
					if(fd == ssock){/* accept pronto*/
						printf("accept creato+++++++++++++++++++++++++++\n");
						fflush(stdout);
						//EC_MINUS1(csock, accept(ssock, NULL, 0), "accept");
						while((csock = accept(ssock, NULL, 0)) == -1);
						FD_SET(csock, &set);
						if(csock >fd_num) fd_num = csock;
					}
					else{ /*Sock I/O*/
						printf("I/O creato+++++++++++++++++++++++++++\n");
						fflush(stdout);
						/* read a request*/
						EC_MINUS1(nread, read(fd, buf, N), "read");
						if(nread == 0 ){
							FD_CLR(fd, &set);
							if(fd == fd_num) fd_num = update(fd, &set);
							EC_MINUS1(e, close(fd), "close");
						}
						else{
							fprintf(stderr, "server: received a request: %s\n", buf);
							//fflush(stdout);
							for (int i = 0; i < strlen(buf); ++i)
							{
								buf[i] = toupper(buf[i]);
							}
							/* write result to client*/
							EC_MINUS1(e, write(csock, buf, nread), "write");
						}

					}
				}
			}
		}
		//fprintf(stderr, "I'm server \n");
	}
	free(buf);
	EC_MINUS1(e, close(ssock), "close");
}
static void* request(void *arg){
	/*simblo di error*/
	int e;
	t_request *re = (t_request*)arg;
	int rid = re->rid;
	struct sockaddr_un sa = re->sa; 
	char *filename = re->filename;
	char *buf = NULL;
	FILE *fin = NULL;
	EC_NULL((buf = calloc(sizeof(char), N)), "calloc");
	EC_NULL((fin = fopen(filename, "r")), "fopen");

	/* configure client*/
	int ssock;
	EC_MINUS1(ssock, socket(AF_UNIX, SOCK_STREAM, 0), "socket");
	while(connect(ssock, (struct sockaddr*)&sa, sizeof(sa)) == -1){
		if(errno = ENOENT) sleep(1);
		else exit(EXIT_FAILURE);
	}
	/* connected */

	while(fgets(buf, N, fin) != NULL){
		EC_MINUS1(e, write(ssock, buf, strlen(buf)), "write");
		EC_MINUS1(e, read(ssock, buf, N), "read");
		fprintf(stderr, "client->request %d: received a reply: %s\n", rid, buf);
		//fflush(stdout);
	}

	EC_MINUS1(e, close(ssock), "close");
	free(buf);
	fclose(fin);
	free(arg);
}