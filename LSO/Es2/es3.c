#define _POSIX_C_SOURCE 200112L
#include <stdio.h>
#include<stdlib.h>
#include <string.h>
#include<unistd.h>

char *strdup(const char *s);
int main(int argc, char *argv[]) {
    if (argc != 3) {
	fprintf(stderr, "use: %s stringa1 stringa2\n", argv[0]);
	return -1;
    }
    char* save1 = NULL;
    char* str1 = strdup(argv[1]);
    char* token1 = strtok_r(str1, " ", &save1);

    while (token1) {
		printf("%s\n", token1);
		char* save2 = NULL;
		char* str2 = strdup(argv[2]);
		char* token2 = strtok_r(str2, " ", &save2);
		while(token2) {
		    printf("%s\n", token2);
		    token2 = strtok_r(NULL, " ", &save2);
		}
		token1 = strtok_r(NULL, " ", &save1);
    }
    return 0;
}