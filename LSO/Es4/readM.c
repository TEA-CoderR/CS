#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<errno.h>

#define FILENAMETXT "mat_dump.txt"
#define FILENAMEDAT "mat_dump.dat"
#define NUM 10
#define BUFFERSIZE 512
// #define EXITFAILURE(s) 			\
// 	perror(s); 					\
// 	exit(EXIT_FAILURE);
#define CHECK_PTR_EXIT(p, s)	\
	if(p == NULL){				\
		perror(s);				\
		exit(EXIT_FAILURE);		\
	}

int isNumber(const char *s, long *val){
	char* e = NULL;
	*val = strtol(s,&e,0);
	if(e != NULL && *e == (char)0) return 1;
	return 0;
}
int main(int argc, char *argv[])
{
	char *fnameTxt = FILENAMETXT, *fnameDat = FILENAMEDAT; 
	long N = NUM;
	// if(argc < 2) {
	// 	//EXITFAILURE(argv[0]);
	// 	perror(argv[0]); 					
	// 	exit(EXIT_FAILURE);
	// }
	
	if(argc == 4){
		if(!isNumber(argv[1], &N)) {
			//EXITFAILURE("<num>");
			perror("<num>"); 					
			exit(EXIT_FAILURE);
		}
		char *tmp = strchr(argv[2],'.');
		if(strcmp(tmp, ".txt") != 0){
			perror(".txt"); 					
			exit(EXIT_FAILURE);
		}
		fnameTxt = argv[2];
		tmp = strchr(argv[3],'.');
		if(strcmp(tmp, ".dat") != 0){
			perror(".dat"); 					
			exit(EXIT_FAILURE);
		}
		fnameDat = argv[3];
	}
	
	FILE *finTxt= NULL, *finDat = NULL;
	CHECK_PTR_EXIT((finTxt = fopen(fnameTxt, "r")), "opening .txt");
	CHECK_PTR_EXIT((finDat = fopen(fnameDat, "r")), "opening .dat");
	double* M1 = (double*)malloc(sizeof(double)*(N*N));
	double* M2 = (double*)malloc(sizeof(double)*(N*N));
	//read in M1
	for (int i = 0; i < N; ++i){
		for (int j = 0; j < N; ++j)
		{
			fscanf(finTxt, "%lf ", &M1[i*N + j]);
			printf("%.2lf ", M1[i*N + j]);
		}
		printf("\n");
	}
	//read in M2
	fread(M2, sizeof(double), N*N, finDat);
	for (int i = 0; i < N; ++i)
	{
		for (int j = 0; j < N; ++j)
		{
			printf("%.2lf ", M2[i*N + j]);
		}
		printf("\n");
	}

	printf("esito confronto :%d\n", memcmp(M1, M2, N*N));
	fclose(finTxt);
	fclose(finDat);
	free(M1);
	free(M2);
	return 0;
}