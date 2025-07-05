#ifndef queue_h
#define queue_h

//v1.0
typedef struct
{
     char **buf;
     int front, rear, size;
     pthread_mutex_t mtx;
     pthread_cond_t empty;
}Queue;
void InitQueue(Queue** q);

void DestroyQueue(Queue *q);

int isEmpty(Queue *q);

//int isFull(Queue *q);

void enQueue(Queue *q, void* e);

char* deQueue(Queue *q);