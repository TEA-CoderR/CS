/**
 * Implementare una threadpool, il size della task_queue e' limitata, 
 * la implementa usando una array per memorizzare tasks, e il size 
 * del pool_queue non e' limitata, usando una link_queue.
 * 
 * @author Yang
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <unistd.h>
#include <errno.h>
#include <stdarg.h>

#include <utils.h>
#include <threadpool.h>

#ifndef TIMER_AUTO_MONITOR
#define TIMER_AUTO_MONITOR 1
#endif
#ifndef THR_NUM_ADD
#define THR_NUM_ADD 2
#endif
#ifndef THR_NUM_REMOVE
#define THR_NUM_REMOVE 2
#endif

/** 
 * aggiunge un task nel task_queue.
 * 
 * @param pool puntatore al thread_pool
 * @param fun puntarore a funzione da chiamare
 * @param arg puntatore a argomento passato della funzione
 * 
 * @return 0 On successo, se pool e' chiuso, return 1, return -1 On error.
 */
int add_task(threadpool_t *pool, void *(*fun)(void *), void *arg){
	if(!pool || !fun) return -1;
	LOCK_RETURN(&pool->mtx, -1);
	while(pool->qlen == pool->queue_size && !pool->shutdown){/*coda piena*/
		WAIT_RETURN(&pool->not_full, &pool->mtx, -1);
	}

	/* controlla pool se e' chiuso*/
	if(pool->shutdown){
		UNLOCK_RETURN(&pool->mtx, -1);
		return 1;
	}
	/*non e' piena piu', posso mettere un task*/
	pool->tail = (pool->tail + 1) % pool->queue_size;
	/*svuota arg se c'e*/
	// if(pool->task_queue[pool->tail].arg != NULL){
	// 	free(pool->task_queue[pool->tail].arg);
	// 	pool->task_queue[pool->tail].arg = NULL;
	// }
	pool->task_queue[pool->tail].fun = fun;
	pool->task_queue[pool->tail].arg = arg;
	++pool->qlen;

	SIGNAL_RETURN(&pool->not_empty, -1);/* notifica un worker a prendere il task*/
	//BROADCAST(&pool->not_empty);/*broadcast all workers a competere il task*/
	UNLOCK_RETURN(&pool->mtx, -1);
	return 0;
}

/** 
 * tolgo un task dal task_queue, "avviene all'interno mutex del worker, 
 * quindi non c'e bisogno ottenere un mutex."
 * 
 * @param pool puntatore al thread_pool
 * 
 * @return un task quel e' preso dal task_queue.
 */
taskfun_t pop_task(threadpool_t *pool){
	if(!pool) EXIT_F("EINVAL");
	pool->head = (pool->head + 1) % pool->queue_size;
	--pool->qlen;
	return pool->task_queue[pool->head];
}

/** 
 * update lo stato del thread.
 * 
 * @param pool puntatore al thread_pool
 * @param mytid il tid del thread da modificare
 * 
 * @return 0 On successo, se pool e' chiuso, return -1.
 */
int update_state(threadpool_t *pool, unsigned int mytid){
	if(!pool){
		perror("EINVAL");
		return -1;
	}
	worker_t *tmp_workers = pool->workers;
	while(tmp_workers != NULL){
		if((unsigned int)tmp_workers->tid == mytid){
			tmp_workers->is_alive = 0;
			break;
		}
		tmp_workers = tmp_workers->next;
	}
	return 0;
}

/** 
 * worker e' fun_thread core del thread_pool, esegue in un ciclo while, ogni volta
 * prova a prendere il task da task_queue in mutex e eseguelo.
 * 
 * @param pool puntatore al thread_pool
 */
void *worker(void *thread_pool){
	if(!thread_pool) pthread_exit(NULL);
	threadpool_t *pool = (threadpool_t*)thread_pool;
	taskfun_t task;
	/* esegue in un ciclo while*/
	while(true){
		LOCK(&pool->mtx);

		/**controlla pool se e' necessario terminare alcuni threads,
		 * se si, thread termina se stesso e exiting - 1.*/
		if(pool->exiting > 0){
			update_state(pool, (unsigned int)pthread_self());
			--pool->exiting;
			--pool->live_thr_num;
			UNLOCK(&pool->mtx);
			pthread_exit(NULL);
		}

		while(pool->qlen == 0 && !pool->shutdown){/*coda vuota*/
			WAIT(&pool->not_empty, &pool->mtx);
		}
		
		/* controlla pool se e' chiuso e se ci sono ancora i task nella coda*/
		if(pool->shutdown && pool->qlen == 0){
			UNLOCK(&pool->mtx);
			pthread_exit(NULL);
		}
		/* coda non vuota piu, prende un task e esegue*/
		task = pop_task(pool);

		SIGNAL(&pool->not_full);/* notifica producer*/
		UNLOCK(&pool->mtx);

		LOCK(&pool->count_busy_num);/* start work, busy_thr_num + 1*/
		++pool->busy_thr_num;
		UNLOCK(&pool->count_busy_num);

		(*task.fun)(task.arg);/* esegue task*/

		LOCK(&pool->count_busy_num);/* end work, busy_thr_num - 1*/
		--pool->busy_thr_num;
		UNLOCK(&pool->count_busy_num);
	}
}

/** 
 * incrementa n thread worker nel workers nel pool, se ci sono alcuni threads
 * gia' terminati, riciclare il primi thread gia' terminato, e usa i suoi tid 
 * ricrea nuovi thread.
 * 
 * @param pool puntatore al thread_pool
 * @param n il numero da incrementare
 * 
 * @return 0 On successo, se pool e' chiuso, return 1, return -1 On error.
 */
int addn_worker(threadpool_t *pool, int n){
	if(!pool) return -1;
	LOCK_RETURN(&pool->mtx, -1);
	/*verifica se e' chiuso thread_pool*/
	if(pool->shutdown == 1){
		UNLOCK_RETURN(&pool->mtx, -1);
		return 1;
	}

	for (int i = 0; i < n; ++i)
	{
		/* tutti sono attivi, crea un nuovo thread worker e mette a head queue*/
		if(pool->live_thr_num == pool->pool_size) {
			worker_t *new_worker = calloc(sizeof(worker_t), 1);
			if(!new_worker){
				perror("calloc worker_t");
				return -1;
			}
			/* inizialliza new_worker*/
			if(pthread_create(&new_worker->tid, NULL, worker, pool) != 0){
				perror("pthread_create");
				return -1;
			}
			new_worker->is_alive = 1;
			new_worker->next = NULL;

			/* head_insert new_worker in workers*/
			if(pool->workers != NULL){
				new_worker->next = pool->workers;
			}
			/*anche se workers e' NULL*/
			pool->workers = new_worker;
			++pool->pool_size;
			//++pool->live_thr_num;
		}
		else{/* live < size, riciclare il primo thread gia' terminato, e ricrea un nuovo thread*/
			worker_t *tmp_workers = pool->workers;

			while(tmp_workers != NULL){
				if(!tmp_workers->is_alive){
					if(pthread_join(tmp_workers->tid, NULL) != 0){
						perror("join");
						return -1;
					}

					/*ricrea un thread worker*/
					if(pthread_create(&tmp_workers->tid, NULL, worker, pool) != 0){
						perror("pthread_create");
						return -1;
					}
					tmp_workers->is_alive = 1;
					//++pool->live_thr_num;
					break;
				}
				tmp_workers = tmp_workers->next;
			}
		}
		++pool->live_thr_num;
	}
	UNLOCK_RETURN(&pool->mtx, -1);

	return 0;
}

/** 
 * decrementa un thread worker nel workers nel pool.
 * 
 * @param pool puntatore al thread_pool
 * @papam n il numero da decrementare
 * 
 * @return 0 On successo, se pool e' chiuso, return 1, return -1 On error.
 */
int removen_worker(threadpool_t *pool, int n){
	if(!pool) return -1;
	LOCK_RETURN(&pool->mtx, -1);
	/*verifica se e' chiuso thread_pool*/
	if(pool->shutdown == 1){
		UNLOCK_RETURN(&pool->mtx, -1);
		return 1;
	}
	/* setta il thr_num da terminare, al massimo termina live_thr_num threads - 1*/
	if(pool->live_thr_num > 1) pool->exiting = (n >= pool->live_thr_num) ? (pool->live_thr_num - 1) : n;
	UNLOCK_RETURN(&pool->mtx, -1);
	return 0;
}

/** 
 * auto_monitor e' thread gestore del thread_pool, esegue in un ciclo while, ogni volta
 * prova a controllare se c'e bisogno add o remove workers nel pool.
 * 
 * @param pool puntatore al thread_pool
 */
static void *auto_monitor(void *thread_pool){
	if(!thread_pool) pthread_exit(NULL);

	threadpool_t *pool = (threadpool_t*)thread_pool;
	bool add = false;
	bool remove = false;

	while(true){
		LOCK(&pool->mtx);
		if(pool->shutdown){/*verifica se e' chiuso thread_pool*/
			UNLOCK(&pool->mtx);
			pthread_exit(NULL);
		}
		/* se ci sono troppi tasks nel task_queue(> 1/2 queue_size), add workers*/
		if(pool->qlen > (pool->queue_size / 2)) add = true;

		/* non causa deadlock mai, perche chi prende conut_busy_num non prende mai mtx*/
		LOCK(&pool->count_busy_num);

		/* se ci sono troppi workers liberi(> 1/2 live_thr_num), remove workers*/
		if((pool->busy_thr_num * 2) < pool->live_thr_num) remove = true;
		UNLOCK(&pool->count_busy_num);
		UNLOCK(&pool->mtx);

		if(add && (addn_worker(pool, THR_NUM_ADD) == -1)){
			perror("addn_worker");
			pthread_exit(NULL);
		}
		if(remove && (removen_worker(pool, THR_NUM_REMOVE) == -1)){
			perror("removen_worker");
			pthread_exit(NULL);
		}
		/* intervallo del ogni gestione*/
		sleep(TIMER_AUTO_MONITOR);
	}
}

/** 
 * install un thread monitor nel monitors nel pool.
 * 
 * @param pool puntatore al thread_pool
 * @param monitor puntatore a monitor, contiene una fun e un arg
 * 
 * @return 0 On successo, se pool e' chiuso, return 1, return -1 On error.
 */
int install_monitor(threadpool_t *pool, taskfun_t *monitor){
	do{
		if(!pool || !monitor) break;
		LOCK_RETURN(&pool->mtx, -1);
		if(pool->shutdown){/*verifica se e' chiuso thread_pool*/
			UNLOCK_RETURN(&pool->mtx, -1);
			return 1;
		}

		monitor_t *new_monitor = calloc(sizeof(monitor_t), 1);
		if(!new_monitor){
			perror("calloc monitor_t");
			break;
		}
		/* inizialliza new_monitor*/
		if(pthread_create(&new_monitor->tid, NULL, monitor->fun, monitor->arg) != 0){
			perror("pthread_create");
			break;
		}
		new_monitor->next = NULL;

		/* head_insert new_monitor in monitors*/
		if(pool->monitors != NULL){
			new_monitor->next = pool->monitors;
		}
		/*anche se monitors e' NULL*/
		pool->monitors = new_monitor;
		UNLOCK_RETURN(&pool->mtx, -1);

		return 0;
	}while(false);

	return -1;
}

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
threadpool_create(int pool_size, int queue_size, ...){
	threadpool_t *pool = NULL;
	do{
		if((pool = calloc(sizeof(threadpool_t), 1)) == NULL){
			perror("calloc threadpool_t");
			break;
		}
		/* inizialliza*/
		pool->monitors = NULL;

		pool->workers = NULL;
		pool->pool_size = 0;
		pool->min_pool_size = 1;
		pool->live_thr_num = 0;
		pool->busy_thr_num = 0;

		pool->queue_size = queue_size;
		pool->qlen = 0;
		pool->head = -1;
		pool->tail = -1;

		pool->exiting = 0;
		pool->shutdown = 0;

		/* alloca queue_size task_queue*/
		if((pool->task_queue = calloc(sizeof(taskfun_t), queue_size)) == NULL){
			perror("calloc taskfun_t");
			break;
		}
		/* inizialliza mutex e cond*/
		if(pthread_mutex_init(&pool->mtx, NULL) != 0){
			perror("mutex init");
			break;
		}
		if(pthread_mutex_init(&pool->count_busy_num, NULL) != 0){
			perror("mutex init");
			break;
		}
		if(pthread_cond_init(&pool->not_empty, NULL) != 0){
			perror("cond init");
			if(&pool->mtx) pthread_mutex_destroy(&pool->mtx);
			if(&pool->count_busy_num) pthread_mutex_destroy(&pool->count_busy_num);
			break;
		}
		if(pthread_cond_init(&pool->not_full, NULL) != 0){
			perror("cond init");
			if(&pool->mtx) pthread_mutex_destroy(&pool->mtx);
			if(&pool->count_busy_num) pthread_mutex_destroy(&pool->count_busy_num);
			if(&pool->not_empty) pthread_cond_destroy(&pool->not_empty);
			break;
		}

		/* install un auto_gestore nel pool*/
		// taskfun_t auto_manager;
		// auto_manager.fun = auto_monitor;
		// auto_manager.arg = pool;
		// if(install_monitor(pool, &auto_manager) == -1){
		// 	perror("add_monitor");
		// 	break;
		// }

		/* legge eventuali monitor passate*/
		va_list list;
		va_start(list, queue_size);/* inizialliza*/
		taskfun_t *new_monitor = NULL;
		while((new_monitor = va_arg(list, taskfun_t*)) != NULL){
			if(install_monitor(pool, new_monitor) == -1){
				perror("add_monitor");
				return NULL;
			}
		}
		va_end(list);

		/* pool_size da allocare non puo' minore a min_size_pool */
		pool_size = (pool_size < pool->min_pool_size) ? pool->min_pool_size : pool_size;
		/* alloca pool_size threads*/
		if(addn_worker(pool, pool_size) == -1){
			perror("addn_worker");
			break;
		}

		return pool;
	}while(false);
	
	return NULL;
}

/**
 * close threadpool.
 * 
 * @param pool puntatore al thread_pool
 * 
 * @return 0 On successo, return -1 On error.
 */
int threadpool_close(threadpool_t *pool){
	if(!pool){
		perror("EINVAL");
		return -1;
	}
	/* set shutdown 1*/             
	LOCK_RETURN(&pool->mtx, -1);
	pool->shutdown = true;
	UNLOCK_RETURN(&pool->mtx, -1);
	return 0;
}

/** 
 * attente threads terminano, e poi free workers, task_queue e pool.
 * 
 * @param pool puntatore al thread_pool
 * 
 * @return 0 On successo, -1 On error.
 */
int threadpool_destroy(threadpool_t *pool){
	if(!pool){
		perror("EINVAL");
		return -1;
	}
	/* set shutdown 1*/ 
	//threadpool_close(pool);

	/* notifica i thread attivi a terminare*/
	for (int i = 0; i < pool->live_thr_num; ++i)
	{
		//BROADCAST_RETURN(&pool->not_empty, -1);
		SIGNAL_RETURN(&pool->not_empty, -1);
	}

	/* close monitors*/
	while(pool->monitors != NULL){
		monitor_t *tmp_monitor = pool->monitors;
		pool->monitors = pool->monitors->next;
		if(pthread_join(tmp_monitor->tid, NULL) != 0){
			perror("join");
			return -1;
		}
		free(tmp_monitor);
	}

	/* close workers*/
	while(pool->workers != NULL){
		worker_t *tmp_worker = pool->workers;
		pool->workers = pool->workers->next;
		if(pthread_join(tmp_worker->tid, NULL) != 0){
			perror("join");
			return -1;
		}
		free(tmp_worker);
	}

	/* close task_queue*/
	if(pool->task_queue) free(pool->task_queue);

	if(pthread_mutex_destroy(&pool->mtx) != 0){
		perror("mutex destroy");
		return -1;
	}
	if(pthread_cond_destroy(&pool->not_empty) != 0){
		perror("cond destroy");
		return -1;
	}
	if(pthread_cond_destroy(&pool->not_full) != 0){
		perror("cond destroy");
		return -1;
	}
	free(pool);
	return 0;
}