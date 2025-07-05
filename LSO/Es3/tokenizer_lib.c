#include<stdio.h>
#include<string.h>
#include<stdatomic.h>

int main(int argc, char *argv[]) {
    if (argc != 3) {
	fprintf(stderr, "use: %s stringa1 stringa2\n", argv[0]);
	return -1;
    }
    char* token1 = strtok(argv[1], " ");

    while (token1) {
	printf("%s\n", token1);
	char* token2 = strtok(argv[2], " ");
	while(token2) {
	    printf("%s\n", token2);
	    token2 = strtok(NULL, " ");
	}
	token1 = strtok(NULL, " ");
    }
    return 0;
}