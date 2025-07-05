#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

int main(int argc, char const *argv[])
{
	for (int i = 1; i < argc; ++i)
	{
		int fdin;
		if((fdin = open(argv[i], O_RDONLY)) == -1){
			perror("FATAL ERROR open in countfile");
			return -1;
		}
		
		struct stat info;
		stat(argv[i], &info);

		long nread = (long)info.st_size / 8; /* ogni long codificato con 8 bytes*/
		//fprintf(stderr, "allocate %ld\n", nread);
		long *buf = calloc(sizeof(long), nread + 1);
		if(read(fdin, buf, nread) == -1){
			perror("FATAL ERROR read in countfile");
			return -1;
		}

		long result = 0;
		for (long i = 0; i < nread; ++i)
		{
			result += buf[i] * i;
		}
		printf("%d :%ld\n", i, result);
		free(buf);
		close(fdin);
	}
	return 0;
}