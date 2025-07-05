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

#define UNIX_PATH_MAX 108
#define SOCKETNAME "./mysocket"

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
static void* woker(void *arg);
static void* request(void *arg);
int main(int argc, char const *argv[])
{
	int ssock, csock;
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
		/* alloc buffer*/
		/* configure server*/
		EC_MINUS1(ssock, socket(AF_UNIX, SOCK_STREAM, 0), "socket");
		EC_MINUS1(e, bind(ssock, (struct sockaddr*)&sa, sizeof(sa)), "bind");
		EC_MINUS1(e, listen(ssock, SOMAXCONN), "listen");
		pthread_t *t = NULL;
		int num = 0;
		while(1){
			fprintf(stderr, "I'm server \n");
			//EC_MINUS1(csock, accept(ssock, NULL, 0), "accept");
			while((csock = accept(ssock, NULL, 0)) == -1);
			/* create a thread deal with request*/
			t_args *arg = NULL;
			EC_NULL((arg = calloc(sizeof(t_args), 1)), "calloc");
			arg->tid = num;
			arg->csock = csock;
			EC_NULL((t = realloc(t, ++num)), "realloc");
			//CREATE(pthread_create(&t[num - 1], NULL, &woker, (void*)arg), "pthread_create");
			pthread_create(&t[num - 1], NULL, &woker, (void*)arg);
		}
		
		EC_MINUS1(e, close(ssock), "close");
		EC_MINUS1(e, close(csock), "close");
		for (int i = 0; i <= num; ++i)
		{
			//JOIN(pthread_join(t[i], NULL), "pthread_join");
			pthread_join(t[i], NULL);
		}
		free(t);
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
static void* woker(void *arg){
	/*simblo di error*/
	int e;
	t_args *args = (t_args*) arg;
	int tid = args->tid;
	int csock = args->csock;
	char *buf = NULL;
	EC_NULL((buf = calloc(sizeof(char), N)), "calloc");
	while(1){
		/* read a request*/
		EC_MINUS1(e, read(csock, buf, N), "read");
		if(!strncmp(buf, "quit", 4)) break;
		fprintf(stderr, "server->thread %d: received a request: %s\n", tid, buf);
		for (int i = 0; i < strlen(buf); ++i)
		{
			buf[i] = toupper(buf[i]);
		}
		/* write result to client*/
		EC_MINUS1(e, write(csock, buf, strlen(buf)), "write");
	}
	free(buf);
	free(arg);
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
	}
	/* stop server*/
	EC_MINUS1(e, write(ssock, "quit", 5), "write");

	EC_MINUS1(e, close(ssock), "close");
	free(buf);
	fclose(fin);
	free(arg);
}