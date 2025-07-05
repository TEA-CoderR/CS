#include<stdio.h>
#include<stdlib.h>
#include<ctype.h>
#include<string.h>

void strtoupper(const char* in, size_t len, char* out){
	for (int i = 0; i < len; ++i)
	{
		out[i] = toupper(in[i]);
	}
}
int main(int argc, char const *argv[])
{
	if(argc != 2){
		printf("usage:%s arg\n", argv[0]);
		return -1;
	}
	int len = strlen(argv[1]);
	char *out = (char*)malloc(sizeof(char) * len);
	strtoupper(argv[1],len,out);
	printf("%s\n", out);
	free(out);
	return 0;
}