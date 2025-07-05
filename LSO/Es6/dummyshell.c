#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<unistd.h>
#include<sys/types.h>
#include<sys/wait.h>

#define N 256
#define MAXARG 64
#define EXIT_F(m)						\
		perror(m); exit(EXIT_FAILURE);			
#define EC_MINUS1(s,m)	\
		if(s == -1) {perror(m); exit(EXIT_FAILURE);}
#define EC_NULL(s,m)	\
		if(s == NULL) {perror(m); exit(EXIT_FAILURE);}

int cmdexit(int argc, char *argv[]){
	if(argc == 1 && !strcmp(argv[0], "exit")) return 1;
	return 0;
}
// void cleanall(char *buf, int argc ,char *argv[]){
// 	free(buf);
// 	for (int i = 0; i < argc; ++i)
// 		free(argv[argc]);
// }
void clean(int argc, char *argv[]){
	for (int i = 0; i < argc; ++i)
		free(argv[argc]);
}
int read_cmdline(int *argc, char *argv[], char *buf, int max){
	if(fgets(buf, N, stdin) != NULL){
		*argc = 0;
		char *s = strtok(buf, " ");
		while(s != NULL){
			if(max < strlen(s)){
				*argc = 0;
				break;
			}
			//strcpy(argv[*argc], s);
			argv[*argc] = strndup(s, strlen(s));
			//printf("argv[%d]:%s\n", *argc, argv[*argc]);
			++(*argc);
			s = strtok(NULL, " ");
		}
		if(*argc != 0){
			argv[*argc - 1][strlen(argv[*argc - 1]) - 1] = '\0';//fgets end with '\n'
			return 0;
		}
	}
	return -1;
}
void execute(int argc, char *argv[]){
	int pid;
	switch(pid = fork()){
	case -1 :{
		printf("Cannot fork\n");
		break;
	}
	case 0 :{
		execvp(argv[0], argv);
		EXIT_F("Cannot exec");
	}
	default:{
		waitpid(pid, NULL, 0);
		clean(argc, argv);
	}
	}
}

int main(void)
{	
	int argc;
	char *argv[MAXARG];
	char *buf = NULL;
	EC_NULL((buf = ((char*)malloc(sizeof(char) * N))), "malloc");
	while(1){
		if(read_cmdline(&argc, argv, buf, MAXARG) != -1){
			if(cmdexit(argc, argv)){
				free(buf);
				clean(argc, argv);
				exit(EXIT_SUCCESS);
			}
			execute(argc, argv);
		}
		else{
			printf("Usage: cmdlinux[256]\n");
		}
	}
	return 0;
}