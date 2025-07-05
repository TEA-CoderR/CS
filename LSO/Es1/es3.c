#include<stdio.h>
#include<stdlib.h>
#include<string.h>

long isNumber(const char * s){
	char *e = NULL;
	long val = strtol(s,&e,0);
	if(e != NULL && *e == (char)0) return val;

	return -1;
}

void printfUsage(const char * program){
	printf("Usage :%s -n <num> -s <tring> -h stampa help\n", program);
}

int main(int argc, char const *argv[])
{
	if(argc == 1){
		printf("troppi pochi elementi\n");
		return -1;
	}
	const char * program = argv[0];
	char foundn = 0, founds = 0;
	long narg = -1;
	char *sarg = NULL;
	// while(*argv != NULL){
	// 	if(**++argv == '-'){
	// 		while(*++(*argv) == '-');

	// 		switch(**argv){
	// 			case 'h' :
	// 				printfUsage(argv[0]);
	// 				return 1;
	// 			case 'n' :
	// 				foundn = 1;
	// 				if(*++(*argv) == '\0'){
	// 					++argv;
	// 					if(*argv == NULL || (narg = isNumber(*argv)) == -1){
	// 						foundn = 0;
	// 						printf("argomento n non valido\n");
	// 					}
	// 				}
	// 				else{
	// 					if((narg = isNumber(*argv)) == -1){
	// 						foundn = 0;
	// 						printf("argomento n non valido\n");
	// 					}
	// 				}
	// 				break;
	// 			case 's' :
	// 				founds = 1;
	// 				if(*++(*argv) == '\0'){
	// 					++argv;
	// 					if(*argv == NULL){
	// 						founds = 0;
	// 						printf("argomento s non valido\n");
	// 					}
	// 					sarg = strdup(*argv);
	// 				}
	// 				else{
	// 					sarg = strdup(*argv);
	// 				}
	// 				break;
	// 			default :{
	// 				printf("argomento non riconoscito\n");
	// 			}
	// 		}
	// 	}
	// }
	while((++argv)[0] != NULL){
		if((*argv)[0] == '-'){
	// while(--argc > 0){
	// 	if((*++argv)[0] == '-'){
			while(*++argv[0] == '-');

			switch(argv[0][0]){
				case 'h' :
					printfUsage(program);
					return 1;
				case 'n' :
					foundn = 1;
					if(argv[0][1] == '\0'){
						++argv, --argc;
						if(argv[0] == NULL || (narg = isNumber(argv[0])) == -1){
							foundn = 0;
							printf("argomento n non valido\n");
						}
					}
					else{
						if((narg = isNumber(&argv[0][1])) == -1){
							foundn = 0;
							printf("argomento n non valido\n");
						}
					}
					break;
				case 's' :
					founds = 1;
					if(argv[0][1] == '\0'){
						++argv, --argc;
						if(argv[0] == NULL){
							founds = 0;
							printf("argomento s non valido\n");
						}
						sarg = strdup(argv[0]);
					}
					else{
						sarg = strdup(&argv[0][1]);
					}
					break;
				default :{
					printf("argomento non riconoscito\n");
				}
			}
		}
	}
	if(foundn) printf("-n: %ld\n", narg);
	if(founds) printf("-s: %s\n", sarg);

	return 0;
}
