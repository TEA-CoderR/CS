#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<unistd.h>
#include<sys/types.h>
#include<sys/wait.h>
#include<time.h>

#define EXIT_F(m)						\
		perror(m); exit(EXIT_FAILURE);			
#define EC_MINUS1(s,m)	\
		if(s == -1) {perror(m); exit(EXIT_FAILURE);}
#define EC_NULL(s,m)	\
		if(s == NULL) {perror(m); exit(EXIT_FAILURE);}

void attende(){
	int pid;
	switch(pid = fork()){
	case -1:{
		printf("Cannot fork\n");
		break;
	}
	case 0:{
		exit(getpid());
		break;
	}
	default:{
		sleep(10);
		waitpid(pid, NULL, 0); 
		printf("pid :%d ", pid);
		printf("ppid :%d\n", getpid());
	}
}
}
int main(void)
{
	// int i = 0;
	// while(i < 10){
	// 	attende();
	// 	++i;
	// }
	int pid;
	for (int i = 0; i < 10; ++i)
	{
		pid = fork();
		if(pid == 0) break;
		printf("lanciato un processo %d\n", pid);
	}

	if(pid){
		sleep(10);
		for (int i = 0; i < 10; ++i)
		{
			waitpid(pid, NULL, 0);
			printf("Terminato un processo %d\n", pid);
		}
	}
	return 0;
}