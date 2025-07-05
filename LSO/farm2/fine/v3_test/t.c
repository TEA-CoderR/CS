#define _POSIX_C_SOURCE 200112L
#include <stdio.h>
#include <unistd.h>
#include <getopt.h>
int getopt(int argc, char * const argv[],
                  const char *optstring);

extern char *optarg;
extern int optind, opterr, optopt;

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
	return 0;
}