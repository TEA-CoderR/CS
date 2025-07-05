#include <stdio.h>
#include <signal.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>


static void gestore(int signum){
	printf("ricevuto %d\n", signum);
	exit(EXIT_FAILURE);
}
int main(int argc, char const *argv[])
{
	struct sigaction s;
	memset(&s, 0, sizeof(s));
	// s.sa_handler = gestore;
	s.sa_handler = SIG_IGN;
	sigaction(SIGINT, &s, NULL);

	for(;;){
		sleep(1);
		printf("111111\n");
	}
	return 0;
}