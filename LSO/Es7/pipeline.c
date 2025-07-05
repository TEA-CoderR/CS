#include<stdio.h>
#include<stdlib.h>
#include<pthread.h>
#include<errno.h>
#include<assert.h>
#include<string.h>

#define EXIT_F(m)                       \
        (perror(m), exit(EXIT_FAILURE));          
#define EC_MINUS1(s,m)  \
        if(s == -1) {perror(m); exit(EXIT_FAILURE);}
#define EC_NULL(s,m)    \
        if(s == NULL) {perror(m); exit(EXIT_FAILURE);}
#define EC_NOT0(s,m)	\
        if(s != 0) {perror(m); exit(EXIT_FAILURE);}

#ifndef FILENAME
#define FILENAME "poem.txt"
#endif
#define N 256

//v1.0
#define MAXSIZE 5
#define LENTH 256
typedef struct
{
        //char **buf;
     char buf[MAXSIZE][LENTH];
     int front, rear;
}Queue;
void InitQueue(Queue** q){
     *q = (Queue*)malloc(sizeof(Queue));
     (*q)->front = -1;
     (*q)->rear = -1;
}
void DestroyQueue(Queue *q){
     free(q);
}
int isEmpty(Queue *q){
     return (q->front == q->rear);
}
int isFull(Queue *q){
     return (q->rear - q->front == MAXSIZE);
}
void enQueue(Queue *q, char* e/*void *e*/){
        //q->buf[++(q->rear)%MAXSIZE] = e;//da implementare
        strncpy(q->buf[++(q->rear)%MAXSIZE], e, LENTH);
}
char* deQueue(Queue *q){
     return q->buf[++(q->front)%MAXSIZE];
}

void Pthread_mutex_lock(pthread_mutex_t *mtx){
        int err;
        if((err = pthread_mutex_lock(mtx)) != 0){
                errno = err;
                perror("lock");
                pthread_exit((void*)4);
        }
        else printf("locked ");
}
void Pthread_mutex_unlock(pthread_mutex_t *mtx){
        int err;
        if((err = pthread_mutex_unlock(mtx)) != 0){
                errno = err;
                perror("unlock");
                pthread_exit((void *)4);
        }
        else printf("unlocked\n");
}
void Pthread_cond_wait(pthread_cond_t *cond, pthread_mutex_t *mtx){
        int err;
        if((err = pthread_cond_wait(cond, mtx)) != 0){
                errno = err;
                perror("wait");
                pthread_exit((void*)4);
        }
}
void Pthread_cond_signal(pthread_cond_t *cond){
        int err;
        if((err = pthread_cond_signal(cond)) != 0){
                errno = err;
                perror("signal");
                pthread_exit((void *)4);
        }
}
#define CREATE(s,m)     \
        if(s != 0) {fprintf(stderr, m);}
// #define JOIN(s,m)    \
//         if(s != 0) {fprintf(stderr, m);}
// #define LOCK(s,m)    \
//      if(s != 0) {errno = s; perror("lock"); pthread_exit(errno);}
// #define UNLOCK(s,m)  \
//      if(s != 0) {errno = s; perror("unlock"); pthread_exit(errno);}
// #define WAIT(s,m)    \
//      if(s != 0) {errno = s; perror("wait"); pthread_exit(errno);}
// #define SIGNAL(s,m)  \
//      if(s != 0) {errno = s; perror("signal"); pthread_exit(errno);}

static pthread_mutex_t mtx1 = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t full1 = PTHREAD_COND_INITIALIZER;
static pthread_cond_t empty1 = PTHREAD_COND_INITIALIZER;
static pthread_mutex_t mtx2 = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t full2 = PTHREAD_COND_INITIALIZER;
static pthread_cond_t empty2 = PTHREAD_COND_INITIALIZER;

Queue *pipe1 = NULL;
Queue *pipe2 = NULL;
static void* myfun_pipe1(void* arg){
        char *buf1 = NULL;
        EC_NULL((buf1 = (char*)malloc(sizeof(char) * N)), "malloc");
        for (int i = 0; i < 20; ++i)
        {
                Pthread_mutex_lock(&mtx1);
                while(isEmpty(pipe1)){
                        printf("is empty, wait!\n"); fflush(stdout);
                        Pthread_cond_wait(&empty1, &mtx1);
                        printf("consumatore waken up!\n"); fflush(stdout);
                }
                strncpy(buf1, deQueue(pipe1), N);
                printf("consumato :%s ", buf1);
                Pthread_cond_signal(&full1);
                Pthread_mutex_unlock(&mtx1);

                Pthread_mutex_lock(&mtx2);
                while(isFull(pipe2)){
                        printf("isfull, wait2!\n"); fflush(stdout);
                        Pthread_cond_wait(&full2, &mtx2);
                        printf("produtore2 waken up!\n"); fflush(stdout);
                }
                enQueue(pipe2, buf1);
                printf("gerenato2 :%s ", buf1);
                Pthread_cond_signal(&empty2);
                Pthread_mutex_unlock(&mtx2);
        }
               
        free(buf1);
        return (void*)0;
}
static void* myfun_pipe2(void* arg){
        char *buf2 = NULL;
        EC_NULL((buf2 = (char*)malloc(sizeof(char) * N)), "malloc");
        for (int i = 0; i < 20; ++i)
        {
                Pthread_mutex_lock(&mtx2);
                while(isEmpty(pipe2)){
                        printf("is empty, wait2!\n"); fflush(stdout);
                        Pthread_cond_wait(&empty2, &mtx2);
                        printf("consumatore2 waken up!\n"); fflush(stdout);
                }
                strncpy(buf2, deQueue(pipe2), N);
                printf("consumato2 :%s ", buf2);
                Pthread_cond_signal(&full2);
                Pthread_mutex_unlock(&mtx2);
                char *s = strtok(buf2, " ");
                while(s != NULL){
                        printf("%s\n", s);
                        s = strtok(NULL, " ");
                }
        }

        free(buf2);
        return (void*)0;
}
int main(int argc, char const *argv[])
{
        pthread_t tid1, tid2;
        int err;
        FILE *filein = NULL;
        char *buf;
        assert(sizeof(int) <= sizeof(void*));
        InitQueue(&pipe1);
        InitQueue(&pipe2);
        CREATE((err = pthread_create(&tid1, NULL, &myfun_pipe1, NULL)), "create fail\n");
        if(err) EXIT_F("create");
        CREATE((err = pthread_create(&tid2, NULL, &myfun_pipe2, NULL)), "create fail\n");
        if(!err){//create success
                EC_NULL((filein = fopen(FILENAME, "r")), "fopen");
                EC_NULL((buf = (char*)malloc(sizeof(char) * N)), "malloc");
                for (int i = 0; i < 20; ++i)
                {
                        Pthread_mutex_lock(&mtx1);
                        while(isFull(pipe1)){
                                printf("isfull, wait!\n"); fflush(stdout);
                                Pthread_cond_wait(&full1, &mtx1);
                                printf("produtore waken up!\n"); fflush(stdout);
                        }
                        if(fgets(buf, N, filein) != NULL){
                                enQueue(pipe1, buf);
                                printf("gerenato :%s ", buf);
                        }
                        Pthread_cond_signal(&empty1);
                        Pthread_mutex_unlock(&mtx1);
                }
        }
        fclose(filein);
        free(buf);
        pthread_join(tid1, NULL);
        pthread_join(tid2, NULL);
        DestroyQueue(pipe1);
        DestroyQueue(pipe2);
        return 0;
}