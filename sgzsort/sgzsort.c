#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>

#include <container.h>

#ifndef FILENAME
#define FILENAME "config.txt"
#endif

#ifndef NBUCKET
#define NBUCKET 10
#endif

#ifndef NBUFFER
#define NBUFFER 10
#endif

int countPriority(int *bucket, char *id, int len){
	int priority = 0;
	for (int i = 0; i < len; ++i)
	{
		if(i == 0 && bucket[i] < 2) ++priority;
		else if(i == 1 && bucket[i] < 2) ++priority;
		else if(bucket[i] < 1) ++priority;
	}

	return priority;
}

void find_max_priority(container_t *container, int *bucket, int len, int second){
	char *max_id = NULL;
	int maxpriority = 0;
	node_t *tmp_node = container->head_result;
	while(tmp_node != NULL){
		tmp_node->priority = countPriority(bucket, tmp_node->id, len);
		if(tmp_node->priority > maxpriority){
			maxpriority = tmp_node->priority;
			max_id = tmp_node->id;
		}

		tmp_node = tmp_node->next;
	}
	printf("%s ", max_id);
	if(second){
		for (int i = 0; i < len; ++i)
		{
			++bucket[(int)(max_id[i]) - 48];
		}
	}
	remove_id(container, max_id, sizeof(max_id));
}

/**
 * number hit 10 19 05 ==> 2 '0', 2 '1', 1 '5', 1 '9'
 */
int main(int argc, char const *argv[])
{
	int nline, ngroup, len;
	char buf[NBUFFER];
	memset(buf, '0', sizeof(buf));
	container_t *container = NULL;
	FILE *fin = NULL;
	if((fin = fopen(FILENAME, "r")) == NULL){
		perror("file not exist");
		exit(EXIT_FAILURE);
	}

	container = container_create();
	nline = 0;
	while(fgets(buf, NBUFFER, fin) != NULL){
		// char *c = strchr(buf, '\n'); *c = '\0';
		len = strlen(buf) - 1;
		char *id = calloc(sizeof(char), len);
		id = strndup(buf, len);
		//fprintf(stdout, "read %s\n", id);
		add_id(container, 0, id);
		++nline;
	}
	print_results(container);

	ngroup = nline / 3;
	//printf("%d %d\n", nline, ngroup);

	for (int i = 0; i < ngroup; ++i)
	{
		int bucket[NBUCKET];
		memset(bucket, 0, sizeof(bucket));
		for (int i = 0; i < NBUCKET; ++i)
		{
			bucket[i] = 0;
		}

		node_t *tmp_node = container->head_result;
		//first elem
		printf("%s ", (char*)tmp_node->id);
		for (int i = 0; i < len; ++i)
		{
			++bucket[(int)(tmp_node->id[i]) - 48];
			//printf("1111 %d ", (int)(tmp_node->id[i]) - 48);
		}

		tmp_node = container->head_result;
		container->head_result = container->head_result->next;
		remove_node(container, tmp_node, sizeof(tmp_node->id));

		//second elem
		find_max_priority(container, bucket, len, 1);

		//terzo elem
		find_max_priority(container, bucket, len, 0);
		printf("\n");

		for (int i = 0; i < NBUCKET; ++i)
		{
			printf("%d ", i);
		}
		printf("\n");
		for (int i = 0; i < NBUCKET; ++i)
		{
			printf("%d ", bucket[i]);
		}
		printf("\n");
	}

	//print_results(container);
	container_destroy(container);
	fclose(fin);
	return 0;
}