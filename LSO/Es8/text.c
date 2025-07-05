#include<stdio.h>
#include<stdlib.h>
#include<string.h>

int main(int argc, char const *argv[])
{
	char *s = "i am the first";
	printf("%s\n", s);
	// void** buf = calloc(sizeof(void*), 1);
	// long *i = calloc(sizeof(int), 1);
	// *i = 6;
	// buf[0] = i;
	// //*(long*)buf[0] = *i;
	// printf("i: %p buf: %p\n", i, buf[0]);
	// printf("i: %ld buf: %ld\n", *i, *(long*)buf[0]);
	// free(i);
	// printf("i: %p buf: %p\n", i, buf[0]);
	// printf("i: %ld buf: %ld\n", *i, *(long*)buf[0]);
	// free(buf);

	/*test ok*/
	// void** buf = calloc(sizeof(void*), 1);
	// char *i = calloc(sizeof(char), 2);
	// strncpy(i, "ok", 2);
	// buf[0] = calloc(sizeof(void), 2);
	// //buf[0] = i;
	// strncpy(buf[0], i, 2);
	// printf("i: %p buf: %p\n", i, buf[0]);
	// printf("i: %s buf: %s\n", i, (char*)buf[0]);
	// free(i);
	// printf("i: %p buf: %p\n", i, buf[0]);
	// printf("i: %s buf: %s\n", i, (char*)buf[0]);
	// free(buf[0]);
	// free(buf);

	// void *s = "text";
	// int len = strlen((char*)s);
	// printf("%d\n", len);

	// void** buf = calloc(sizeof(void*), 1);
	// void *i = calloc(sizeof(void), 2);
	// strncpy((char*)i, "ok", 2);
	// buf[0] = calloc(sizeof(void), 2);
	// //buf[0] = i;
	// strncpy((char*)buf[0], (char*)i, 2);
	// printf("i: %p buf: %p\n", i, buf[0]);
	// printf("i: %s buf: %s\n", (char*)i, (char*)buf[0]);
	// free(i);
	// printf("i: %p buf: %p\n", i, buf[0]);
	// printf("i: %s buf: %s\n", (char*)i, (char*)buf[0]);
	// free(buf[0]);
	// free(buf);
	return 0;
}