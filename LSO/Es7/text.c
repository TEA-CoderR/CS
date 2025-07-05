#include<stdio.h>

void f(char **s){
	*s = "ffagga";
	printf("f %s\n", *s);
}
int main(int argc, char const *argv[])
{
	char *s = "12345";
	printf("prima %s\n", s);
	f(&s);
	printf("dopo %s\n", s);
	return 0;
}