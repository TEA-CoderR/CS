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

#define SOCKETNAME "./mysocket"
#define EC_MINUS1(r,c,e)                                             \
    if((r = c) == -1) {errno = r, perror(e); exit(errno);}

typedef struct countfile_s{
	int ssock;
	char *filename;
}countfile_t;

// void *fun(void *arg){
// 	countfile_t *cf = (countfile_t*)arg;
// 	// char *filename = (char*)arg;
// 	printf("%p : %p\n", cf, arg);
// 	printf("%p : %p\n", cf->filename, arg);
// 	for (int i = 0; i < cf->i; ++i)
// 	{
// 		printf("%s\n", cf->filename);
// 		sleep(1);
// 		//exit(1);
// 	}

// 	free(cf->filename);
// 	free(cf);
// 	//free(filename);
// 	//free(arg);
// }

typedef struct msg_s{
	long result;
	char *filename;
}msg_t;

void *fun(void *arg){
	countfile_t *cf = (countfile_t*)arg;
	// msg_t *msg = calloc(sizeof(msg_t), 1);
	// msg->result = 0;
	// msg->filename = calloc(sizeof(char), 255);
	// strncpy(msg->filename, cf->filename, 255);

	//write(cf->ssock, msg, sizeof(msg_t));

	printf("2 :%p : %s\n", cf, cf->filename);
	write(cf->ssock, cf->filename, strlen(cf->filename));
	printf("fun exiting\n");
	fflush(stdout);
	// free(msg->filename);
	// free(msg);
}

int e;
int main(int argc, char const *argv[])
{
	int ssock, csock;
	/* Initialze sockaddr*/
	struct sockaddr_un sa;
	memset(&sa, '0' ,sizeof(sa));
	strncpy(sa.sun_path, SOCKETNAME, strlen(SOCKETNAME) + 1);
	sa.sun_family = AF_UNIX;
	/* fork a process client*/
	int pid1;
	EC_MINUS1(pid1, fork(), "fork");
	if(pid1){// server
		/* configure server*/
		EC_MINUS1(ssock, socket(AF_UNIX, SOCK_STREAM, 0), "socket");
		EC_MINUS1(e, bind(ssock, (struct sockaddr*)&sa, sizeof(sa)), "bind");
		EC_MINUS1(e, listen(ssock, SOMAXCONN), "listen");

		while((csock = accept(ssock, NULL, 0)) == -1){
			if(errno = EINTR){
			}
			else{
				perror("accept");
				//r = EXIT_FAILURE
			}
		}

		// msg_t *msg = calloc(sizeof(msg_t), 1);
		// msg->result = 0;
		// msg->filename = calloc(sizeof(char), 255);
		char *buf = calloc(sizeof(char), 255);
		int n1 = read(csock, buf, 255);
		buf[n1] = '\0';
		printf("3 :%p : %s\n", buf, buf);

		// int n = read(csock, msg->filename, 255);
		// msg->filename[n] = '\0';
		// read(ssock, msg, sizeof(msg_t));
		// printf("3 :%p : %s\n", msg, msg->filename);

		// read(ssock, msg, sizeof(msg_t));
		// sleep(2);
		// printf("%p : %s\n", msg, msg->filename);

		// read(ssock, msg, sizeof(msg_t));
		// sleep(2);
		// printf("%p : %s\n", msg, msg->filename);

		waitpid(pid1, NULL, 0);

	}
	else{//client
		ssock = socket(AF_UNIX, SOCK_STREAM, 0);
		while(connect(ssock, (struct sockaddr*)&sa, sizeof(sa)) == -1){
			if(errno = ENOENT) sleep(1);
			else exit(EXIT_FAILURE);
		}

		pthread_t tid;
		countfile_t *cf = calloc(sizeof(countfile_t), 1);
		cf->filename = calloc(sizeof(char), 255);
		cf->ssock = ssock;
		strncpy(cf->filename, "text.txt", 255);
		printf("1 :%p : %s\n", cf, cf->filename);
		//write(ssock, cf->filename, strlen(cf->filename));
		pthread_create(&tid, NULL, fun, cf);

		// strncpy(buf, "text1.txt", 10);
		// countfile_t cf1;
		// cf.ssock = ssock;
		// cf.filename = buf;
		// pthread_create(&tid, NULL, fun, &cf1);

		// strncpy(buf, "text2.txt", 10);
		// countfile_t cf2;
		// cf.ssock = ssock;
		// cf.filename = buf;
		// pthread_create(&tid, NULL, fun, &cf2);

		//pthread_join(tid, NULL);
		//sleep(5);
		free(cf->filename);
		free(cf);
	}




	// char filename[10] = "text.txt";
	// //char *buf = calloc(sizeof(char), 10);
	// //strncpy(buf, filename, 9);

	// countfile_t *cf;
	// cf = calloc(sizeof(countfile_t), 1);;
	// cf->i = 5;
	// cf->filename = calloc(sizeof(char), 10);;
	// strncpy(cf->filename, filename, 9);
	// printf("%p : %p\n", cf->filename, cf);
	// //printf("%p : %p\n", cf.filename, &cf);
	// pthread_t tid;
	// pthread_create(&tid, NULL, fun, cf);
	// //sleep(1);
	// //strncpy(buf, "cambio", 6);
	// //sleep(2);
	// //free(buf);
	// pthread_join(tid, NULL);

	unlink(SOCKETNAME);
	return 0;
}