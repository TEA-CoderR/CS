#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<unistd.h>

int isNumber(char *s){
	char *e = NULL;
	long val = strtol(s,&e,0);
	if(e != NULL && *e == (char)0) return val;

	return -1;
}
void printfUsage(const char *program){
	printf("Usage :%s -n <num> -s <string> -h\n", program);
	exit(-1);
}
int main(int argc, char *const argv[])
{
	if(argc == 1){
		printf("troppi elementi\n");
		exit(-1);
	}
	const char *program = argv[0];

	char foundn = 0, founds = 0;
	long narg = -1;
	char *sarg = NULL;
	int opt;
	while((opt = getopt(argc, argv, "n:s:h")) != -1){
		switch(opt){
		case 'h': {
			printfUsage(program);
		}break;
		case 'n': {
			if((narg = isNumber(optarg)) != -1) foundn = 1;
		}break;
		case 's': {
			founds = 1;
			sarg = strdup(optarg);
		}break;
		default:
			printf("argomento non valido\n");
		}
	}

	if(foundn) printf("-n %ld\n", narg);
	if(founds) printf("-s %s\n", sarg);
	if(!foundn && !founds) printfUsage(program);
	return 0;
}