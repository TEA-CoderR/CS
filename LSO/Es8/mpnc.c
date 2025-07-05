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
#define EC_NOT0(s,m)    \
        if(s != 0) {perror(m); exit(EXIT_FAILURE);}

#ifndef FILENAME
#define FILENAME "poem.txt"
#endif

#define K 100
#define M 20
#define N 20
#define EOS "0x1"

// #define LOCK(s, m)    \
//      if((s = pthread_mutex_lock(m)) != 0) {errno = s; perror("lock"); pthread_exit(errno);} //else printf("locked ");
// #define UNLOCK(s,m)  \
//      if((s = pthread_mutex_unlock(m)) != 0) {errno = s; perror("unlock"); pthread_exit(errno);} //else printf("unlocked ");
// #define WAIT(s,c,m)    \
//      if((s = pthread_cond_wait(c, m)) != 0) {errno = s; perror("wait"); pthread_exit(errno);}
// #define SIGNAL(s,c)  \
//      if((s = pthread_cond_signal(c)) != 0) {errno = s; perror("signal"); pthread_exit(errno);}

#define CREATE(s,m)     \
        if(s != 0) {errno = s; perror(m); pthread_exit(errno);}
#define JOIN(s,m)     \
        if(s != 0) {errno = s; perror(m); pthread_exit(errno);}

void LOCK(pthread_mutex_t *mtx){
        int err;
        if((err = pthread_mutex_lock(mtx)) != 0){
                errno = err;
                perror("lock");
                pthread_exit((void*)&errno);
        }
        else printf("locked ");
}
void UNLOCK(pthread_mutex_t *mtx){
        int err;
        if((err = pthread_mutex_unlock(mtx)) != 0){
                errno = err;
                perror("unlock");
                pthread_exit((void *)&errno);
        }
        else printf("unlocked\n");
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

typedef struct node{
        void *data;
        struct node *next;
}node_t;
typedef node_t* LinkQueue;
typedef struct
{
        LinkQueue head;
        LinkQueue tail;
        int size;
        pthread_mutex_t mtx;
        pthread_cond_t empty;
}Queue;
Queue* InitQueue(Queue* q){
        EC_NULL((q = (Queue*)malloc(sizeof(Queue))), "malloc");
        q->head = NULL;
        q->tail = NULL;
        q->size = 0;
        EC_NOT0(pthread_mutex_init(&q->mtx, NULL), "pthread_mutex_init");
        EC_NOT0(pthread_cond_init(&q->empty, NULL), "pthread_cond_init");
        return q;
}
void DestroyQueue(Queue *q){
        LinkQueue tmp = NULL;
        while(q->head != NULL){
                tmp = q->head;
                q->head = (q->head)->next;
                free(tmp);
        }
        free(q);
}
int isEmpty(Queue *q){
        return (q->size == 0);
}
// int isFull(Queue *q){
//         return (q->rear - q->front == MAXSIZE);
// }
int enQueue(Queue *q, void* e){
        if(!q || !e){
                errno = EINVAL;
                return -1;
        }
        LinkQueue new = NULL;
        EC_NULL((new = calloc(sizeof(node_t), 1)), "malloc");
        //alloca memoria di data
        int len = strlen((char*)e);
        EC_NULL((new->data = calloc(sizeof(void), len)), "calloc");
        strncpy((char*)new->data, (char*)e, len);
        //new->next = NULL;
        LOCK(&q->mtx);
        LinkQueue prev = NULL;
        while(q->tail != NULL){
                prev = q->tail;
                q->tail = q->tail->next;
        }
        if(!prev){
                prev->next = new;
                new->next = q->tail;
                q->tail = new;
                ++q->size;
        }
        else{//vuota coda
                new->next = q->head;
                q->head = new;
                q->tail = q->head;
                ++q->size;
        }
        UNLOCK(&q->mtx);
        return 0;
}
void* deQueue(Queue *q){
        LinkQueue tmp = NULL;
        LOCK(&q->mtx);
        while(isEmpty(q)) WAIT(&q->empty, &q->mtx);
        //alloca memoria di data
        void *data;
        int len = strlen((char*)q->head->data);
        EC_NULL((data = calloc(sizeof(void), len)), "calloc");
        strncpy((char*)data, (char*)q->head->data, len);
        tmp = q->head;
        q->head = q->head->next;
        UNLOCK(&q->mtx);
        free(tmp);
        return data;
}

typedef struct
{
        int tid;
        Queue *q;
        int start;
        int stop;
}t_args;

static void* producer(void* arg){
        char buf[2];
        t_args args = *(t_args*)arg;
        Queue *q = args.q;
        int tid = args.tid;
        int start = args.start;
        int stop = args.stop;

        for (int i = start; i < stop; ++i)
        {
                buf[0] = (char)i;
                buf[1] = (char)i;
                enQueue(q, buf);
                printf("tid: %d producato %s\n", tid, buf);
        }

        return (void*)0;
}
static void* consumer(void* arg){
        char *buf = NULL;
        t_args args = *(t_args*)arg;
        Queue *q = args.q;
        int tid = args.tid;
        // int start = args.start;
        // int stop = args.stop;

        //for (int i = start; i < stop; ++i)
        for(;;)
        {
                buf = (char*)deQueue(q);
                if(!strcmp(buf, EOS)) exit(6);
                printf("tid: %d consumato %s\n", tid, buf);
        }
        return (void*)0;
}
int main(int argc, char const *argv[])
{
        Queue *q = InitQueue(q);
        pthread_t *tid;
        t_args *args;
        EC_NULL((tid = calloc(sizeof(pthread_t), M + N)), "calloc tid");
        EC_NULL((args = calloc(sizeof(t_args), M + N)), "calloc args");

        int chunk = K / M, r = K % M, start = 0;
        for (int i = 0; i < M; ++i)
        {
                args[i].tid = i;
                args[i].q = q;
                args[i].start = start;
                args[i].stop = start + chunk + (i < r ? 1 : 0);
                start += chunk + (i < r ? 1 : 0);
        }

        for (int i = M; i < M + N; ++i)
        {
                args[i].tid = i;
                args[i].q = q;
                args[i].start = 0;
                args[i].stop = chunk + (i < r ? 1 : 0);
        }

        for (int i = 0; i < M; ++i)
        {
                CREATE(pthread_create(&tid[i], NULL, &producer, (void*)&args[i]), "create fail");
        }

        for (int i = M; i < M + N; ++i)
        {
                CREATE(pthread_create(&tid[i], NULL, &consumer, (void*)&args[i]), "create fail");
        }

        for (int i = 0; i < M; ++i)
        {
                JOIN(pthread_join(tid[i], NULL), "join");
        }

        for (int i = 0; i < N; ++i)
        {
                enQueue(q, EOS);
        }

        for (int i = M; i < M + N; ++i)
        {
                JOIN(pthread_join(tid[i], NULL), "join");
        }

        free(tid);
        free(args);
        DestroyQueue(q);
        return 0;
}