#include<stdio.h>
#include<stdlib.h>
#include<pthread.h>
#include<errno.h>
#include<assert.h>

#define EXIT_F(m)                       \
        perror(m); exit(EXIT_FAILURE);          
#define EC_MINUS1(s,m)  \
        if(s == -1) {perror(m); exit(EXIT_FAILURE);}
#define EC_NULL(s,m)    \
        if(s == NULL) {perror(m); exit(EXIT_FAILURE);}
#define EC_NOT0(s,m)	\
        if(s != 0) {perror(m); exit(EXIT_FAILURE);}

//v1.0
// #define MAXSIZE 5
// typedef struct
// {
// 	int buf[MAXSIZE];
// 	int front, rear;
// }Queue;
// void InitQueue(Queue** q){
// 	*q = (Queue*)malloc(sizeof(Queue));
// 	(*q)->front = -1;
// 	(*q)->rear = -1;
// }
// void DestroyQueue(Queue *q){
// 	free(q);
// }
// int isEmpty(Queue *q){
// 	return (q->front == q->rear);
// }
// int isFull(Queue *q){
// 	return (q->rear - q->front == MAXSIZE);
// }
// void enQueue(Queue *q, int e){
//	q->rear = (q->rear + 1) % MAXSIZE;
// 	q->buf[q->rear] = e;
// }
// int deQueue(Queue *q){
//	q->front = (q->front + 1) % MAXSIZE;
// 	return q->buf[q->front];
// }
//v2.0
#define MAXSIZE 5
typedef struct queue
{
	int index;
	int elem;
	struct queue *next;
}queueNode;
typedef queueNode* LinkQueue;
typedef struct
{
	LinkQueue linkq;
	int front;
	int rear;	
}myLinkQueue;
void stampa(LinkQueue q){
	while(q != NULL){
		printf("--------------%d %d\n", q->index, q->elem);
		q = q->next;
	}
}
void insert(LinkQueue *q, int index, int elem){
	LinkQueue new = (LinkQueue)malloc(sizeof(queueNode));
	if(new != NULL){
		new->index = index;
		new->elem = elem;
		new->next = NULL;
		LinkQueue prev = NULL;
		LinkQueue current = *q;
		while(current != NULL){
			prev = current;
			current = current->next;
		}
		if(prev != NULL){
			prev->next = new;
			new->next = current;
		}
		else{//empty queue
			new->next = *q;
			*q = new;
		}
		// LinkQueue tmp = *q;
		// if(tmp != NULL){
		// 	while(tmp->next != NULL){
		// 		tmp = tmp->next;
		// 	}
		// 	tmp->next = new;
		// 	new->next = NULL;
		// }
		// else{//empty queue
		// 	new->next = *q;
		// 	*q = new;
		// }
		// stampa(*q);
		// printf("----------------\n");
	}
	else{
		EXIT_F("memoria esaurita");
	}
}
void modify(LinkQueue q, int index, int elem){
	while(q != NULL && q->index != index){
		q = q->next;
	}
	if(q != NULL) q->elem = elem;
}
int get(LinkQueue q, int index){
	while(q != NULL && q->index != index){
		q = q->next;
	}
	if(q != NULL) return q->elem;
	return -1;
}
void InitQueue(myLinkQueue** myq){
	*myq = (myLinkQueue*)malloc(sizeof(myLinkQueue));
	(*myq)->linkq = NULL;
	(*myq)->front = -1;
	(*myq)->rear = -1;
	for (int i = 0; i < MAXSIZE; ++i)
	{
		insert(&((*myq)->linkq), i, -1);
		//printf("%d:%p %d %d %d\n", i, (*myq)->linkq, ((*myq)->linkq)->index, (*myq)->front, (*myq)->rear);
	}
	//stampa((*myq)->linkq);
}
void DestroyQueue(myLinkQueue *q){
	LinkQueue tmp = NULL;
	while(q->linkq != NULL){
		tmp = q->linkq;
		q->linkq = (q->linkq)->next;
		free(tmp);
	}
	free(q);
}
int isEmpty(myLinkQueue *q){
	return (q->front == q->rear);
}
int isFull(myLinkQueue *q){
	return (q->rear - q->front == MAXSIZE);
}
void enQueue(myLinkQueue *q, int e){
	modify((q->linkq), ++(q->rear)%MAXSIZE, e);
}
int deQueue(myLinkQueue *q){
	return get(q->linkq, ++(q->front)%MAXSIZE);
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
#define CREATE(s,m)	\
        if(s != 0) {fprintf(stderr, m);}
// #define JOIN(s,m)	\
//         if(s != 0) {fprintf(stderr, m);}
// #define LOCK(s,m)	\
// 	if(s != 0) {errno = s; perror("lock"); pthread_exit(errno);}
// #define UNLOCK(s,m)	\
// 	if(s != 0) {errno = s; perror("unlock"); pthread_exit(errno);}
// #define WAIT(s,m)	\
// 	if(s != 0) {errno = s; perror("wait"); pthread_exit(errno);}
// #define SIGNAL(s,m)	\
// 	if(s != 0) {errno = s; perror("signal"); pthread_exit(errno);}

static pthread_mutex_t mtx = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t full = PTHREAD_COND_INITIALIZER;
static pthread_cond_t empty = PTHREAD_COND_INITIALIZER;

myLinkQueue *q = NULL;
//Queue *q = NULL;
static void* myfun(void* arg){
	for (int i = 0; i < 20; ++i)
	{
		Pthread_mutex_lock(&mtx);
		while(isEmpty(q)){
			printf("is empty, wait!\n"); fflush(stdout);
			Pthread_cond_wait(&empty, &mtx);
			printf("consumatore waken up!\n"); fflush(stdout);
		}
		printf("consumato :%d ", deQueue(q));
		Pthread_cond_signal(&full);
		Pthread_mutex_unlock(&mtx);
	}

	return (void*)0;
}
int main(int argc, char const *argv[])
{
	pthread_t tid;
	int err;
	assert(sizeof(int) <= sizeof(void*));
	//InitQueue(mlq);
	InitQueue(&q);
	CREATE((err = pthread_create(&tid, NULL, &myfun, NULL)), "create fail\n");
	if(!err){//create success
		for (int i = 0; i < 20; ++i)
		{
			Pthread_mutex_lock(&mtx);
			while(isFull(q)){
				printf("isfull, wait!\n"); fflush(stdout);
				Pthread_cond_wait(&full, &mtx);
				printf("produtore waken up!\n"); fflush(stdout);
			}
			enQueue(q, i);
			printf("gerenato :%d ", i);
			Pthread_cond_signal(&empty);
			Pthread_mutex_unlock(&mtx);
		}
	}
	pthread_join(tid, NULL);
	DestroyQueue(q);
	return 0;
}


//v1.0
// #define MAXSIZE 5
// typedef struct
// {
// 	int buf[MAXSIZE];
// 	int front, rear;
// }Queue;
// void InitQueue(Queue* q){
// 	q = (Queue*)malloc(sizeof(Queue));
// 	q->front = -1;
// 	q->rear = -1;
// }
// void DestroyQueue(Queue *q){
// 	free(q);
// }
// int isEmpty(Queue *q){
// 	return (q->front == q->rear);
// }
// int isFull(Queue *q){
// 	return (q->rear - q->front == MAXSIZE);
// }
// void enQueue(Queue *q, int e){
// 	q->buf[++(q->rear)%MAXSIZE] = e;
// }
// int deQueue(Queue *q){
// 	return q->buf[++(q->front)%MAXSIZE];
// }


//v3.0
// #define MAXSIZE 5
// typedef struct queue
// {
// 	int index;
// 	int elem;
// 	struct queue *next;
// }queueNode;
// typedef Queue* LinkQueue;
// typedef struct
// {
// 	LinkQueue front;
// 	LinkQueue rear;
// }myLinkQueue;
// void insert(LinkQueue* q, int index, int elem){
// 	LinkQueue new = (LinkQueue)malloc(sizeof(queueNode));
// 	if(new != NULL){
// 		new->index = index;
// 		new->elem = elem;
// 		//new->next = NULL;
// 		LinkQueue prev = NULL;
// 		LinkQueue current = *q;
// 		while(current != NULL){
// 			prev = current;
// 			current = current->next;
// 		}
// 		if(prev != NULL){
// 			prev->next = new;
// 			new->next = current;
// 		}
// 		else{//empty queue
// 			new->next = *q;
// 			*q = new;
// 		}
// 	}
// 	else{
// 		EXIT_F("memoria esaurita");
// 	}
// }
// void modify(LinkQueue q, int index, int elem){
// 	while(q != NULL && q->index != index){
// 		q = q->next;
// 	}
// 	if(q != NULL) q->elem = elem;
// }
// int get(LinkQueue q, int index){
// 	while(q != NULL && q->index != index){
// 		q = q->next;
// 	}
// 	if(q != NULL) return q->elem;
// 	return -1;
// }
// void InitQueue(myLinkQueue** myq){
// 	*myq = (myLinkQueue*)malloc(sizeof(myLinkQueue));
// 	(*myq)->front = NULL;
// 	(*myq)->rear = NULL;
// }
// void DestroyQueue(myLinkQueue *q){
// 	LinkQueue tmp = NULL;
// 	while(q->front != NULL){
// 		tmp = q->front;
// 		q->front = (q->front)->next;
// 		free(tmp);
// 	}
// 	// free(q->front);
// 	// free(q->rear);
// }
// int isEmpty(myLinkQueue *q){
// 	return ((q->front)->index == (q->rear)->index);
// }
// int isFull(myLinkQueue *q){
// 	return ((q->rear)->index - (q->front)->index == MAXSIZE);
// }
// void enQueue(myLinkQueue *q, int e){
// 	insert(&(q->rear), ++((q->rear)->index), e);
// }
// int deQueue(myLinkQueue *q){
// 	int e = get(q->front, ++((q->front)->index));
// 	LinkQueue tmp = q->front;
// 	q->front = (q->front) = next;
// 	free(tmp);
// 	return e;
// }