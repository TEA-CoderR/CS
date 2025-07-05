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

int main(void)
{
	int pid;
	for (int i = 0; i < 5; ++i)
	{
		pid = fork();
		if(pid){
			waitpid(pid, NULL, 0);
			for (int j = i + 1; j < 5; ++j)
			{
				printf("-");
			}
			printf("%d Terminato un processo %d\n", getppid(), getpid());
			break;
		}
		else{
			for (int j = i + 1; j < 5; ++j)
			{
				printf("-");
			}
			printf("%d lanciato un processo %d\n", getppid(), getpid());
		}
	}

	return 0;
}




// #include<stdio.h>
// #include<stdlib.h>
// #include<string.h>
// #include<unistd.h>
// #include<sys/types.h>
// #include<sys/wait.h>
// #include<time.h>

// #define EXIT_F(m)						\
// 		perror(m); exit(EXIT_FAILURE);			
// #define EC_MINUS1(s,m)	\
// 		if(s == -1) {perror(m); exit(EXIT_FAILURE);}
// #define EC_NULL(s,m)	\
// 		if(s == NULL) {perror(m); exit(EXIT_FAILURE);}

// static void attende(int n){
// 	int pid;
// 	if(pid = fork()){
// 		waitpid(pid, NULL, 0); 
// 		for (int i = 0; i < n; ++i)
// 		{
// 			printf("-");
// 		}
// 		printf("%d Terminato un processo %d\n", getppid(), getpid());
// 	}
// 	else{
// 		for (int i = 0; i < n; ++i)
// 		{
// 			printf("-");
// 		}
// 		printf("%d lanciato un processo %d\n", getppid(), getpid());
// 		if(n > 0) attende(--n);
// 	}
// }
// int main(void)
// {
// 	attende(4);
// 	return 0;
// }