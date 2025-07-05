#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<unistd.h>
#include<time.h>

#ifndef N
#define N 1000
#endif
#ifndef K1
#define K1 0
#endif
#ifndef K2
#define K2 10
#endif

int isNumber(char *s, long *val){
	char *e = NULL;
	*val = strtol(s,&e,0);
	if(e != NULL && *e == (char)0) return 1;
	return 0;
}

void nRandom(long n, long k1, long k2){
	int *narray = (int*)malloc(sizeof(int)*(k2 - k1));
	for(int i = 0; i < (k2-k1); ++i){
		narray[i] = 0;
	}
	unsigned int seed = time(NULL);
	for(int i = 0; i < n; ++i){
		int index = k1 + rand_r(&seed)%(k2 - k1);
		++narray[index % (k2 -k1)];
	}
	for (int i = 0; i < (k2-k1); ++i)
	{
		printf("%ld : %.2f%%\n", i + k1, (float)narray[i]*100/n);	
	}
	free(narray);
}
int main(int argc, char *argv[])
{
	if(argc != 4){
		printf("Usage :%s N K1 K2\n", argv[0]);
		exit(-1);
	}
	long n = -1, k1 = -1, k2 = -1;
	if(isNumber(argv[1], &n) && isNumber(argv[2], &k1) 
		&& isNumber(argv[2], &k2) && n > 0 && k1 >= 0 
		&& k2 > 0 && k2 > k1) nRandom(n, k1, k2);
	else nRandom(N, K1, K2);

	return 0;
}