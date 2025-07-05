#include<stdio.h>
#include<stdlib.h>

#ifndef INIT_VALUE
#define INIT_VALUE 100
#endif

int somma_r(int x, int *sum){
	*sum += x;
	printf("sum :%d\n", *sum);
	return *sum;
}
long isNumber(char *s){
	char *e = NULL;
	long val = strtol(s,&e,0);
	if(e != NULL && *e == (char)0) return val;
	return -1;
}
int main(int argc, char *argv[])
{
	if(argc != 2) {
		perror("argc");
		exit(EXIT_FAILURE);
	}
	int n = -1;
	if((n = isNumber(argv[1])) == -1){
		perror("argoment");
		exit(EXIT_FAILURE);
	}
	int sum = 0;
	sum = somma_r(INIT_VALUE, &sum);
	int val = -1;
	printf("%d\n", n);
	for (int i = 0; i < n; ++i)
	{
		// if(scanf("%d", &val) != 1){
		// 	printf("insert <num>\n");
		// 	return EXIT_FAILURE;
		// }
		// while(1){
		// 	fflush(stdin);
		// 	if(scanf("%d", &val) == 1) break;
		// 	printf("insert <num>\n");
		// }
		while((scanf("%d", &val)) == 0){
			while(getchar() != '\n');//svuota buffer stdin
			printf("insert <num>\n");
		}
		sum = somma_r(val, &sum);
	}
	return 0;
}
