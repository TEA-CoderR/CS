/**
 * Implementare una threadpool, il size della task_queue e' limitata, 
 * la implementa usando una array per memorizzare tasks, e il size 
 * del pool_queue non e' limitata, usando una link_queue.
 * 
 * @author Yang
 */

#include <pthread.h>

/**
 * @struct definisce la entita' della coda concorrente del task.
 */
typedef struct taskfun_s{
	void *(*fun)(void *);
	void *arg;
}taskfun_t;

/**
 * @struct definisce una struttura di un thread monitor, usa link_queue;
 */
typedef struct monitor_s{
	pthread_t tid;
	struct monitor_s *next;
}monitor_t;

/**
 * @struct definisce una struttura di un thread worker, usa link_queue;
 */
typedef struct worker_s{
	pthread_t tid;
	bool is_alive;
	struct worker_s *next;
}worker_t;

/**
 * @struct definisce la struttura di un thread_pool, contiene un link_queue
 * workers, e una array tasks, i workers competono in un mutex per ottenere
 * i tasks.
 */
typedef struct {
	pthread_mutex_t mtx;/* lock la struttura, tranne busy_thr_num*/
	pthread_mutex_t count_busy_num;/* lock busy_thr_num*/
	pthread_cond_t not_full;/* cond notifica master*/
	pthread_cond_t not_empty;/* cond notifica workers*/

	monitor_t *monitors;/* monitors thread del pool*/

	worker_t *workers; /* workers thread del pool*/

	taskfun_t *task_queue; /* task array*/

	int pool_size;
	int min_pool_size;
	int live_thr_num; /* il numero del thread attivo*/
	
	int busy_thr_num;/* il numero del thread runing*/

	int queue_size;
	int qlen;
	int head, tail;

	int exiting; /* il numero del thread da terminare*/
	bool shutdown;/* close flag*/ 
}threadpool_t;

/** 
 * aggiunge un task nel task_queue.
 * 
 * @param pool puntatore al thread_pool
 * @param fun puntarore a funzione da chiamare
 * @param arg puntatore a argomento passato della funzione
 * 
 * @return 0 On successo, se pool e' chiuso, return 1, On error return -1.
 */
int add_task(threadpool_t *pool, void *(*fun)(void *), void *arg);

/** 
 * tolgo un task dal task_queue, "avviene all'interno mutex del worker, 
 * quindi non c'e bisogno ottenere un mutex."
 * 
 * @param pool puntatore al thread_pool
 * 
 * @return un task quel e' preso dal task_queue.
 */
taskfun_t pop_task(threadpool_t *pool);

/** 
 * update lo stato del thread.
 * 
 * @param pool puntatore al thread_pool
 * @param mytid il tid del thread da modificare
 * 
 * @return 0 On successo, se pool e' chiuso, return -1.
 */
int update_state(threadpool_t *pool, unsigned int mytid);

/** 
 * worker e' thread core del thread_pool, esegue in un ciclo while, ogni volta
 * prova a prendere il task da task_queue in mutex e eseguelo.
 * 
 * @param pool puntatore al thread_pool
 */
void *worker(void *thread_pool);

/** 
 * incrementa n thread worker nel workers nel pool, se ci sono alcuni threads
 * gia' terminati, riciclare il primi thread gia' terminato, e usa i suoi tid 
 * ricrea nuovi thread.
 * 
 * @param pool puntatore al thread_pool
 * @param n il numero da incrementare
 * 
 * @return 0 On successo, se pool e' chiuso, return 1, On error return -1.
 */
int addn_worker(threadpool_t *pool, int n);

/** 
 * decrementa un thread worker nel workers nel pool.
 * 
 * @param pool puntatore al thread_pool
 * @papam n il numero da decrementare
 * 
 * @return 0 On successo, se pool e' chiuso, return 1, On error return -1.
 */
int removen_worker(threadpool_t *pool, int n);
	
/** 
 * install un thread monitor nel monitors nel pool.
 * 
 * @param pool puntatore al thread_pool
 * @param monitor puntatore a monitor, contiene una fun e un arg
 * 
 * @return 0 On successo, se pool e' chiuso, return 1, On error return -1.
 */
int install_monitor(threadpool_t *pool, taskfun_t *monitor);

/**
 * crea e inizialliza un threadpool, chiamata da un solo thread.
 * 
 * @param pool_size il numero del threads da creare nel pool
 * @param queue_size il size della codaTask
 * @param va_list se esiste, contiene dei thread monitor da creare
 * 
 * @return puntatore a pool creato On successo, NULL On error.
 */
threadpool_t *
threadpool_create(int pool_size, int queue_size, ...);

/**
 * close threadpool.
 * 
 * @param pool puntatore al thread_pool
 * 
 * @return 0 On successo, return -1 On error.
 */
int threadpool_close(threadpool_t *pool);

/** 
 * attente threads terminano, e poi free workers, task_queue e pool.
 * 
 * @param pool puntatore al thread_pool
 * 
 * @return 0 On successo, -1 On error.
 */
int threadpool_destroy(threadpool_t *pool);