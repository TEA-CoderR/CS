#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>


int isNumber(const char *s, long *val){
    char* e = NULL;
    *val = strtol(s, &e, 0);
    if(e != NULL && *e == (char)0) return 1;
    return 0;
}

void t(int argc, char *argv[], int n){
	int n_thread;
	int len_task_queue;
	int delay;
	long arg_n = -1, arg_q = -1, arg_t = -1;
	char *dirname = NULL;
	int opt;
	while((opt = getopt(argc, argv, ":n:q:d:t:")) != -1){
		switch(opt){
		case 'n':{
			printf("%c\n", opt);
			if(isNumber(optarg, &arg_n) && arg_n > 0) n_thread = arg_n;
		}break;
		case 'q':{
			printf("%c\n", opt);
			if(isNumber(optarg, &arg_q) && arg_q > 0) len_task_queue = arg_q;
		}break;
		case 'd':{
			printf("%c\n", opt);
			dirname = optarg;
		}break;
		case 't':{
			printf("%c\n", opt);
			if(isNumber(optarg, &arg_t) && arg_t > 0) delay = arg_t;
		}break;
		case ':':
		case '?': 
			break;
		default:;
		}
	}
	while(argv[optind] != NULL){
		printf("%d : %s\n", optind, argv[optind]);
		++optind;
	}
}

void f(int argc, char *argv[]){
	long arg_n = -1, arg_q = -1, arg_t = -1;
	int opt;
	while((opt = getopt(argc, argv, ":n:q:d:t:")) != -1){
		switch(opt){
		case 'n':{
			printf("%c\n", opt);
		}break;
		case 'q':{
			printf("%c\n", opt);
		}break;
		case 'd':{
			printf("%c\n", opt);
		}break;
		case 't':{
			printf("%c\n", opt);
		}break;
		case ':':{
			fprintf(stderr, "l'opzione '-%c' richiede un argomento, usa DEFAULT\n", opt);
		}break;
		case '?':{
			fprintf(stderr, "l'opzione '-%c' non e' riconoscito\n", opt);
		}break;
		default:;
		}
	}
	while(argv[optind] != NULL){
		printf("%d : %s\n", optind, argv[optind]);
		++optind;
	}
}

int main(int argc, char *argv[])
{
	int opt;
	while((opt = getopt(argc, argv, ":n:q:d:t:")) != -1){
		switch(opt){
		case 'n':{
			printf("%c\n", opt);
		}break;
		case 'q':{
			printf("%c\n", opt);
		}break;
		case 'd':{
			printf("%c\n", opt);
		}break;
		case 't':{
			printf("%c\n", opt);
		}break;
		case ':':{
			fprintf(stderr, "l'opzione '-%c' richiede un argomento, usa DEFAULT\n", opt);
		}break;
		case '?':{
			fprintf(stderr, "l'opzione '-%c' non e' riconoscito\n", opt);
		}break;
		default:;
		}
	}
	while(argv[optind] != NULL){
		printf("%d : %s\n", optind, argv[optind]);
		++optind;
	}
	// int n;
	// if(fork()){
	// 	t(argc, argv ,n);
	// }
	//t(argc, argv);
	// int opt;
	// while((opt = getopt(argc, argv, ":n:q:d:t:")) != -1){
	// 	switch(opt){
	// 	case 'n':{
	// 		printf("%c\n", opt);
	// 		//if(isNumber(optarg, &arg_n) && arg_n > 0) n_thread = arg_n;
	// 	}break;
	// 	case 'q':{
	// 		printf("%c\n", opt);
	// 		//if(isNumber(optarg, &arg_q) && arg_q > 0) len_task_queue = arg_q;
	// 	}break;
	// 	case 'd':{
	// 		printf("%c\n", opt);
	// 		//dirname = optarg;
	// 	}break;
	// 	case 't':{
	// 		printf("%c\n", opt);
	// 		//if(isNumber(optarg, &arg_t) && arg_t > 0) delay = arg_t;
	// 	}break;
	// 	case ':':
	// 	case '?': 
	// 		break;
	// 	default:;
	// 	}
	// }
	// while(argv[optind] != NULL){
	// 	printf("%d : %s\n", optind, argv[optind]);
	// 	++optind;
	// }
	return 0;
}