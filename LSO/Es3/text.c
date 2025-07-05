#include<stdio.h>

int main(int argc, char const *argv[])
{
	int n = 0;
	while((scanf("%d", &n)) != EOF){
		printf("%d\n", n);
	}
	printf("%d\n", n);
	return 0;
}