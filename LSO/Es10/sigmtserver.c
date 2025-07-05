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
#define SIZEPOOL 10

#define EXIT_F(m)		\
	(perror(m), exit(EXIT_FAILURE));
#define EC_MINUS1(e,c,m)  \
	if((e = c) == -1) {errno = e, perror(m); exit(errno);}
#define EC_NULL(s,m)    \
	if(s == NULL) {perror(m); exit(EXIT_FAILURE);}
#define EC_NOT0(s,m)    \
    if(s != 0) {perror(m); exit(EXIT_FAILURE);}
// #define CREATE(s,m)     \
// 	if(s != 0) {errno = s; perror(m); pthread_exit(errno);}
// #define JOIN(s,m)     \
// 	if(s != 0) {errno = s; perror(m); pthread_exit(errno);}

typedef struct pool{
	int size;
	int *pool;
	pthread_mutex_t mtx;
	pthread_cond_t empty;
}pthread_pool;
typedef struct targs{
	int tid;
	int csock;
}t_args;
typedef struct request{
	int rid;
	char *filename;
	struct sockaddr_un sa;
}t_request;
void LOCK(pthread_mutex_t *mtx){
    int err;
    if((err = pthread_mutex_lock(mtx)) != 0){
        errno = err;
        perror("lock");
        pthread_exit((void*)&errno);
    }
    //else printf("locked ");		
}
void UNLOCK(pthread_mutex_t *mtx){
    int err;
    if((err = pthread_mutex_unlock(mtx)) != 0){
        errno = err;
        perror("unlock");
        pthread_exit((void *)&errno);
    }
    //else printf("unlocked\n");
}
void WAIT(pthread_cond_t *cond, pthread_mutex_t *mtx){
    int err;
    if((err = pthread_cond_wait(cond, mtx)) != 0){
        errno = err;
        perror("wait");
        pthread_exit((void*)&errno);
    }
}
void SIGNAL(pthread_cond_t *cond){
    int err;
    if((err = pthread_cond_signal(cond)) != 0){
        errno = err;
        perror("signal");
        pthread_exit((void *)&errno);
    }
}

pthread_pool *pool = NULL;
/*simblo di error*/
int e;
volatile sig_atomic_t closeflag = 0;

static void sighandler(int sig); 
static pthread_pool *initPool(pthread_pool *pool, int size);
static int get(pthread_pool *pool);
static void destroypool(pthread_pool *pool);
static void* woker(void *arg);
static void* request(void *arg);
static void cleanall(pthread_t *t, int num, int ssock, int pid);
static int spawn_thread(pthread_pool *pool, pthread_t *t, int csock);
int main(int argc, char const *argv[])
{
	int ssock, csock;
	/* Initialze sockaddr*/
	struct sockaddr_un sa;
	strncpy(sa.sun_path, SOCKETNAME, UNIX_PATH_MAX);
	sa.sun_family = AF_UNIX;
	/* fork a process client*/
	int pid1;
	EC_MINUS1(pid1, fork(), "fork");
	if(pid1){// server
	    sigset_t set, oldset;
	    sigemptyset(&set);
	    sigaddset(&set, SIGINT);
	    sigaddset(&set, SIGQUIT);
	    sigaddset(&set, SIGTERM);
	    sigaddset(&set, SIGHUP);
	    /* maschera i segnali prima di installare*/
	    EC_MINUS1(e, pthread_sigmask(SIG_BLOCK, &set, &oldset), "pthread_sigmask");
	    struct sigaction s;
	    memset(&s, 0 ,sizeof(s));
	    s.sa_handler = sighandler;
	    // sigset_t handlermask;
	    // sigemptyset(&handlermask);
	    // sigaddset(&handlermask, SIGINT);
	    // sigaddset(&handlermask, SIGQUIT);
	    // sigaddset(&handlermask, SIGTERM);
	    // sigaddset(&handlermask, SIGHUP);
	    //s.sa_flags = SA_RESTART;
	    EC_MINUS1(e, sigaction(SIGINT, &s, NULL), "sigaction");
	    EC_MINUS1(e, sigaction(SIGQUIT, &s, NULL), "sigaction");
	    EC_MINUS1(e, sigaction(SIGTERM, &s, NULL), "sigaction");
	    EC_MINUS1(e, sigaction(SIGHUP, &s, NULL), "sigaction");

		/* configure server*/
		EC_MINUS1(ssock, socket(AF_UNIX, SOCK_STREAM, 0), "socket");
		EC_MINUS1(e, bind(ssock, (struct sockaddr*)&sa, sizeof(sa)), "bind");
		EC_MINUS1(e, listen(ssock, SOMAXCONN), "listen");

		/* reset oldset*/
	    EC_MINUS1(e, pthread_sigmask(SIG_SETMASK, &oldset, NULL), "pthread_sigmask");

		pthread_t *t = NULL;
		EC_NULL((t = calloc(sizeof(pthread_t), SIZEPOOL)), "calloc");
		EC_NULL((pool = calloc(sizeof(pthread_pool), 1)), "calloc");
		pool = initPool(pool, SIZEPOOL);
		while(!closeflag){
			//EC_MINUS1(e, write(2, "I'm server \n", 12), "write");
			fprintf(stderr, "I'm server \n");
			//EC_MINUS1(csock, accept(ssock, NULL, 0), "accept");
			if((csock = accept(ssock, NULL, 0)) == -1){
				if(errno = EINTR){
					printf("%d\n", closeflag);
					if(closeflag) break;
				}
				else{
					perror("accept");
					//r = EXIT_FAILURE
				}
			}
			/* create a thread deal with request*/
			//CREATE(pthread_create(&t[num - 1], NULL, &woker, (void*)arg), "pthread_create");
			if(spawn_thread(pool, t, csock) == -1) break;
		}
		printf("11111111111111111111111\n");
		unlink(SOCKETNAME);
		cleanall(t, SIZEPOOL, ssock, pid1);
		free(pool);
		destroypool(pool);
	}
	else{//client
		t_request *re = NULL;
		EC_NULL((re = calloc(sizeof(t_request), 1)), "calloc");
		pthread_t t;
		re->rid = 0;
		re->sa = sa;
		re->filename = "t1.txt";
		//CREATE(pthread_create(&t, NULL, &request, (void*)re), "pthread_create");
		pthread_create(&t, NULL, request, (void*)re);

		t_request *re2 = NULL;
		EC_NULL((re2 = calloc(sizeof(t_request), 1)), "calloc");
		pthread_t t2;
		re2->rid = 1;
		re2->sa = sa;
		re2->filename = "t2.txt";
		// CREATE(pthread_create(&t2, NULL, &request, (void*)re2), "pthread_create");
		pthread_create(&t2, NULL, request, (void*)re2);

		// JOIN(pthread_join(t, NULL), "pthread_join");
		// JOIN(pthread_join(t2, NULL), "pthread_join");
		pthread_join(t, NULL);
		pthread_join(t2, NULL);

		exit(EXIT_SUCCESS);
	}
	
	//EC_MINUS1(e, waitpid(pid1, NULL, 0), "waitpid");
	return 0;
}

static void sighandler(int sig){
	//closeflag = 1;
	switch(sig){
    case SIGINT:{
    	EC_MINUS1(e, write(1, "SIGINT catturato\n", 17), "write");
        closeflag = 1;
        break;
    }
    case SIGQUIT:{
    	EC_MINUS1(e, write(1, "SIGQUIT catturato\n", 18), "write");
        closeflag = 1;
        break;
    }
    case SIGTERM:{
        EC_MINUS1(e, write(1, "SIGTERM catturato\n", 18), "write");
        closeflag = 1;
        break;
    }
	case SIGHUP:{
        EC_MINUS1(e, write(1, "SIGHUP catturato\n", 17), "write");
        closeflag = 1;
        break;
    }
    default:;
    }
} 
static pthread_pool *initPool(pthread_pool *pool, int size){
	pool->size = size;
	EC_NULL((pool->pool = calloc(sizeof(int), size)), "calloc");
	EC_NOT0(pthread_mutex_init(&(pool->mtx), NULL), "pthread_mutex_init");
	EC_NOT0(pthread_cond_init(&(pool->empty), NULL), "pthread_cond_init");
	return pool;
}
static int get(pthread_pool *pool){
	for (int i = 0; i < pool->size; ++i)
	{
		if(pool->pool[i] == 0){
			pool->pool[i] == 1;
			return i;
		}
	}
	return -1;
}
static void destroypool(pthread_pool *pool){
	free(pool->pool);
}
static void cleanall(pthread_t *t, int num, int ssock, int pid){
	EC_MINUS1(e, close(ssock), "close");
	//EC_MINUS1(e, close(csock), "close");
	for (int i = 0; i < num; ++i)
	{
		//JOIN(pthread_join(t[i], NULL), "pthread_join");
		pthread_join(t[i], NULL);
	}
	free(t);
	EC_MINUS1(e, waitpid(pid, NULL, 0), "waitpid");
	//unlink(SOCKETNAME);
	fprintf(stderr, "server closed\n");
	exit(EXIT_SUCCESS);
}
static int spawn_thread(pthread_pool *pool, pthread_t *t, int csock){
	// sigset_t mask, oldmask;
	// sigemptyset(&mask);
    // sigaddset(&mask, SIGINT);
    // sigaddset(&mask, SIGQUIT);
    // sigaddset(&mask, SIGTERM);
    // sigaddset(&mask, SIGHUP);
    // /* maschera i segnali con oldmask*/
    // if(pthread_sigmask(SIG_BLOCK, &mask, &oldmask) != 0){
    // 	fprintf(stderr, "FATAL ERROR, pthread_sigmask\n");
    // 	return -1;
    // }
    int index = -1;
    LOCK(&pool->mtx);
    while((index = get(pool)) == -1) WAIT(&pool->empty, &pool->mtx);
    UNLOCK(&pool->mtx);

    t_args *arg = NULL;
	EC_NULL((arg = calloc(sizeof(t_args), 1)), "calloc");
	arg->tid = index;
	arg->csock = csock;
	if(pthread_create(&t[index], NULL, woker, (void*)arg) != 0){
		fprintf(stderr, "FATAL ERROR, pthread_create\n");
		EC_MINUS1(e, close(csock), "close");
		return -1;;
	}
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
	int nread;
	while(1){
		/* read a request*/
		EC_MINUS1(nread, read(csock, buf, N), "read");
		buf[nread] = '\0';
		if(!strncmp(buf, "quit", 4)) break;
		fprintf(stderr, "server->thread %d: received a request: %s\n", tid, buf);
		// EC_MINUS1(e, write(2, "server: received a request: ", 28), "write");
		// EC_MINUS1(e, write(2, buf, strlen(buf)), "write");
		// EC_MINUS1(e, write(2, "\n", 1), "write");
		for (int i = 0; i < strlen(buf); ++i)
		{
			buf[i] = toupper(buf[i]);
		}
		/* write result to client*/
		EC_MINUS1(e, write(csock, buf, strlen(buf)), "write");
	}
	free(buf);
	free(arg);
	//free(args);
	LOCK(&pool->mtx);
	pool->pool[tid] = 0;
    SIGNAL(&pool->empty);
    UNLOCK(&pool->mtx);
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
	int nread;
	while(fgets(buf, N, fin) != NULL){
		EC_MINUS1(e, write(ssock, buf, strlen(buf)), "write");
		EC_MINUS1(nread, read(ssock, buf, N), "read");
		buf[nread] = '\0';
		fprintf(stderr, "client->request %d: received a reply: %s\n", rid, buf);
		// EC_MINUS1(e, write(2, "client: received a reply: ", 26), "write");
		// EC_MINUS1(e, write(2, buf, strlen(buf)), "write");
		// EC_MINUS1(e, write(2, "\n", 1), "write");
	}
	/* stop server*/
	EC_MINUS1(e, write(ssock, "quit", 5), "write");

	EC_MINUS1(e, close(ssock), "close");
	//free(filename);
	//free(re);
	free(buf);
	fclose(fin);
	free(arg);
}