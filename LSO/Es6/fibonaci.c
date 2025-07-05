#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>

#define EXIT_F(m)                       \
        (perror(m), exit(EXIT_FAILURE);)          
#define EC_MINUS1(s,m)  \
        if(s == -1) {perror(m); exit(EXIT_FAILURE);}
#define EC_NULL(s,m)    \
        if(s == NULL) {perror(m); exit(EXIT_FAILURE);}
/* 
 * Calcola ricorsivamente il numero di Fibonacci dell'argomento 'n'.
 * La soluzione deve effettuare fork di processi con il vincolo che 
 * ogni processo esegua 'doFib' al più una volta.  
 * Se l'argomento doPrint e' 1 allora la funzione stampa il numero calcolato 
 * prima di passarlo al processo padre. 
 */
static int i;
static void doFib1(int n, int doPrint){
        static int f = 0;
        static int f_1 = 0;
        static int f_2 = 0;
        int pid;
        switch(pid = fork()){
        case -1:{
            printf("Cannot fork\n");
            break;
        }
        case 0:{
            if(n == i){
                f_2 = 0;
                printf("n:%d\tf:%d\tf1:%d\tf2:%d\n", n, f, f_1, f_2);
                exit(0);
            }
            else if(n == i - 1){
                f_1 = 1;
                printf("n:%d\tf:%d\tf1:%d\tf2:%d\n", n, f, f_1, f_2);
                exit(1);
            }
            else{
                f = f_1 + f_2;
                f_2 = f_1;
                f_1 = f;
                printf("n:%d\tf:%d\tf1:%d\tf2:%d\n", n, f, f_1, f_2);
                exit(f);
            }
            break;
        }
        default:{
            if(n > 0){
                //printf("i:%d\tn:%d\tn-i:%d\n", i, n, n - i);
                doFib1(--n, doPrint);
            }
            int status;
            //sleep(1);
            EC_MINUS1((waitpid(pid, &status, 0)), "waitpid");
            if(doPrint && WIFEXITED(status)){
                printf("%d\n", WEXITSTATUS(status));
            }
        }
        }
}
static void doFib(int n, int doPrint){
        static int f = 0;
        static int f_1 = 0;
        static int f_2 = 0;
        int pid;
        switch(pid = fork()){
        case -1:{
            printf("Cannot fork\n");
            break;
        }
        case 0:{
            if(n == 0){
                exit(0);
            }
            else if(n == 1){
                exit(1);
            }
            else exit(-1);
            // if(n == 0){
            //     f_2 = 0;
            //     printf("n:%d\tf:%d\tf1:%d\tf2:%d\n", n, f, f_1, f_2);
            //     exit(0);
            // }
            // else if(n == 1){
            //     f_1 = 1;
            //     printf("n:%d\tf:%d\tf1:%d\tf2:%d\n", n, f, f_1, f_2);
            //     exit(1);
            // }
            // else{
            //     f = f_1 + f_2;
            //     f_2 = f_1;
            //     f_1 = f;
            //     printf("n:%d\tf:%d\tf1:%d\tf2:%d\n", n, f, f_1, f_2);
            //     exit(f);
            // }
            break;
        }
        default:{
            if(n > 0) doFib(--n, doPrint);
            int status;
            //sleep(1);
            EC_MINUS1((waitpid(pid, &status, 0)), "waitpid");
            if(doPrint && WIFEXITED(status)){
                if(n == 0){
                    f_2 = status;
                    printf("n:%d\tf:%d\tf1:%d\tf2:%d\n", n, f, f_1, f_2);
                }
                else if(n == 1){
                    f_1 = status;
                    printf("n:%d\tf:%d\tf1:%d\tf2:%d\n", n, f, f_1, f_2);
                }
                else{
                    f = f_1 + f_2;
                    f_2 = f_1;
                    f_1 = f;
                    printf("n:%d\tf:%d\tf1:%d\tf2:%d\n", n, f, f_1, f_2);
                }
                //printf("%d\n", WEXITSTATUS(status));
            }
        }
        }
}

int main(int argc, char *argv[]) {
    // questo programma puo' calcolare i numeri di Fibonacci solo fino a 13.  
    const int NMAX=13;
    int arg;
    
    if(argc != 2){
	fprintf(stderr, "Usage: %s <num>\n", argv[0]);
	return EXIT_FAILURE;
    }
    arg = atoi(argv[1]);
    if(arg <= 0 || arg > NMAX){
	fprintf(stderr, "num deve essere compreso tra 1 e 13\n");
	return EXIT_FAILURE;
    }  
    i = arg; 
    doFib1(arg, 1);
    return 0;
}