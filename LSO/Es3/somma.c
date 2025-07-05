#include<stdio.h>
#include<stdlib.h>

#ifndef INIT_VALUE
#define INIT_VALUE 100
#endif

int somma(int x){
	static int sum = 0;
	sum += x;
	printf("sum :%d\n", sum);
	return sum;
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
	somma(INIT_VALUE);
	int val = -1;
	printf("%d\n", n);
	for (int i = 0; i < n; ++i)
	{
		while(scanf("%d", &val) != 1){
			fflush(0);
			printf("insert <num>\n");
			//fflush(1);			
		}
		somma(val);
	}
	return 0;
}