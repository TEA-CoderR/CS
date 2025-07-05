#include <stdio.h>
int main(int argc, char const *argv[])
{
	char n[2];
	n[0] = '1';
	n[1] = '2';
	printf("%d\n", (int)n[0] - 48);
	printf("%d\n", (int)n[1]);
	return 0;
}