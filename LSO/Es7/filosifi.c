#include<stdio.h>
#include<stdlib.h>
#include<pthread.h>
#include<errno.h>
#include<time.h>
#include<unistd.h>
#include<assert.h>

#define N 10
#define EXIT_F(m)                       \
        (perror(m), exit(EXIT_FAILURE));          
#define EC_MINUS1(s,m)  \
        if(s == -1) {perror(m); exit(EXIT_FAILURE);}
#define EC_NULL(s,m)    \
        if(s == NULL) {perror(m); exit(EXIT_FAILURE);}
#define EC_NOT0(s,m)	\
        if(s != 0) {perror(m); exit(EXIT_FAILURE);}

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
static pthread_mutex_t mtx[N] = {PTHREAD_MUTEX_INITIALIZER};

void gosleep(int n){
	unsigned int seed = time(NULL);
	struct timespec time;
	time.tv_sec = rand_r(&seed) % n;
	time.tv_nsec = rand_r(&seed) % 1000000000;
	nanosleep(&time, 0);
}
void pensa(int pos){
	printf("%d: meditare\n", pos);
	gosleep(2);
}
void mangia(int pos){
	printf("%d: mangiare\n", pos);
	gosleep(3);
}
static void* myfun(void* arg){
	assert(sizeof(int) <= sizeof(void*));
	int pos = *(int*)arg, left = pos - 1, right = pos;
	for (int i = 0; i < 100; ++i)
	{
		pensa(pos);
		if(pos % 2){//dispari
			Pthread_mutex_lock(&mtx[left]);
			Pthread_mutex_lock(&mtx[right]);
			mangia(pos);
			Pthread_mutex_unlock(&mtx[right]);
			Pthread_mutex_unlock(&mtx[left]);
		}
		else{
			Pthread_mutex_lock(&mtx[right]);
			Pthread_mutex_lock(&mtx[left]);
			mangia(pos);
			Pthread_mutex_unlock(&mtx[left]);
			Pthread_mutex_unlock(&mtx[right]);
		}
	}

	return (void*)0;
}
int main(int argc, char const *argv[])
{
	pthread_t tid[N];
	// for (int i = 0; i < N; ++i)
	// {
	// 	mtx[i] = PTHREAD_MUTEX_INITIALIZER;
	// }
	int err;
	int arg;
	for (int i = 0; i < N; ++i)
	{
		arg = i + 1;
		err = pthread_create(&tid[i], NULL, &myfun, (void*)&arg);
		if(err) EXIT_F("create");
	}	
	for (int i = 0; i < N; ++i)
	{
		pthread_join(tid[i], NULL);
	}
	return 0;
}