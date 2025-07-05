#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>

int main(int argc, char const *argv[])
{	
	for (int i = 1; i < argc; ++i)
	{
		FILE* fin = fopen(argv[i], "rb");
		if(!fin){
			perror("fopen");
			return -1;
		}
		struct stat info;
		stat(argv[i], &info);

		long nread = (long)info.st_size / 8; /* ogni long codificato con 8 bytes*/
		long val, result = 0;
		for (long i = 0; i < nread; ++i)
		{
			fread(&val, sizeof(long), 1, fin);
			result += val * i;
		}
		printf("%d :%ld\n", i, result);
		fclose(fin);
	}
	return 0;
}