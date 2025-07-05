#include<stdio.h>
#include<unistd.h>

int main(int argc, char const *argv[])
{
	int pid = fork();
	if(pid == 0){
		printf("%d sono figlio:%d\n", getpid(), pid);
	}
	else printf("%d sono padre :%d\n", getpid(), pid);
	return 0;
}