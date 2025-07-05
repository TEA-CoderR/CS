#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<errno.h>

#define FILENAMETXT "mat_dump.txt"
#define FILENAMEDAT "mat_dump.dat"
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
int main(int argc, char const *argv[])
{
	if(argc != 2) {
		//EXITFAILURE(argv[0]);
		perror(argv[0]); 					\
		exit(EXIT_FAILURE);
	}
	long N = -1;
	if(!isNumber(argv[1], &N)) {
		//EXITFAILURE("<num>");
		perror("<num>"); 					\
		exit(EXIT_FAILURE);
	}
	
	FILE *foutTxt= NULL, *foutDat = NULL;
	CHECK_PTR_EXIT((foutTxt = fopen(FILENAMETXT, "w")), "opening .txt");
	CHECK_PTR_EXIT((foutDat = fopen(FILENAMEDAT, "w")), "opening .dat");
	double* M = (double*)malloc(sizeof(double)*(N*N));
	for (int i = 0; i < N; ++i)
	{
		for (int j = 0; j < N; ++j)
		{
			M[i*N + j] = (i+j)/2.0;
			printf("%.2lf ", M[i*N + j]);
			//fprintf(foutTxt, "%.2lf ", M[i*N + j]);
			fprintf(foutTxt, "%lf ", M[i*N + j]);
		}
		printf("\n");
		//fprintf(foutTxt, "\n");
	}
	fwrite(M, sizeof(double), N*N, foutDat);

	fclose(foutTxt);
	fclose(foutDat);
	free(M);
	return 0;
}