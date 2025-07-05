#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<errno.h>
#include<ctype.h>
int getopt(int argc, char * const argv[],
              const char *optstring);
extern char *optarg;
extern int optind, opterr, optopt;

#define BUFFERSIZE 512
typedef struct fileNode{
	FILE* fptr;
	char* fn;
	int nline;
	int nw;
	int nc;
	struct fileNode *prev;
	struct fileNode	*next;
}FileNode;
typedef FileNode* fnptr;

void insert(fnptr *fpr, FILE* fptr, char* fn, int nline, int nw, int nc){
	fnptr new = (FileNode*)malloc(sizeof(FileNode));
	if(new != NULL){
		new->fptr = fptr;
		new->fn = strndup(fn, strlen(fn));
		new->nline = nline;
		new->nw = nw;
		new->nc = nc;
		new->prev = NULL;
		new->next = NULL;
		if(*fpr == NULL){
			new->prev = *fpr;
			*fpr = new;
		}
		else{
			(*fpr)->prev = new;
			new->next = *fpr;
			*fpr = new;
		}
	}
	else{
		perror("MEMORIA");
		exit(EXIT_FAILURE);
	}

}

int found(fnptr fpr, char* fn){
	while(fpr != NULL){
		if((strcmp(fpr->fn, fn) == 0)) return 1;
		fpr = fpr->next;
	}
	return 0;
}
int fptrclose(fnptr fpr){
	while(fpr != NULL){
		if((fpr->fptr != NULL)) fclose(fpr->fptr);
		fpr = fpr->next;
	}
	return 0;
}

int parsingFilename(char*** parsingFilename, int argc, char *argv[]){
	int size = 0;
	for (int i = 1; i < argc; ++i)
	{
		if(argv[i][0] == '-') continue;
		*parsingFilename = realloc(*parsingFilename, size + 1);
		size += 1;
		(*parsingFilename)[size - 1] = (char*)malloc(sizeof(char) * strlen(argv[i]));
		(*parsingFilename)[size - 1] = strndup(argv[i], strlen(argv[i]));
		//printf("%s\n", (*parsingFilename)[size - 1]);
	}
	return size;
}

void arg_l(fnptr fpr, char* buf, int size){
	while(fpr != NULL){
		FILE* tmpfp = (fpr)->fptr;
		//printf("tmpfp :%p\n", tmpfp);
		rewind(tmpfp);
		int nl = 0;
		while(!feof(tmpfp)){
			fgets(buf, size, tmpfp);
			//printf("%s\n", buf);
			++nl;
		}
		(fpr)->nline = nl;
		printf("%s :line :%d\n", (fpr)->fn, (fpr)->nline);
		(fpr) = (fpr)->next;
	}
}
void arg_w(fnptr fpr, char* buf, int size){
	if(fpr == NULL) printf("NULL\n");
	while(fpr != NULL){
		FILE* tmpfp = (fpr)->fptr;
		rewind(tmpfp);
		int nw = 0;
		while(!feof(tmpfp)){
			fgets(buf, size, tmpfp);
			int i = 0;
			// while(isspace(buf[i++]));
			// --i;
			if(isspace(buf[i])) {
				while(isspace(buf[++i]));
			}
			while(!iscntrl(buf[i])){
				if(isspace(buf[i-1])) ++nw;
				if(isspace(buf[++i])) {
					while(isspace(buf[++i]));
				}
			}
			//printf("%s : w :%d\n", (fpr)->fn, nw);
		}
		(fpr)->nw = nw;
		printf("%s : w :%d\n", (fpr)->fn, (fpr)->nw);
		(fpr) = (fpr)->next;
	}
}
void arg_c(fnptr fpr, char* buf, int size){
	if(fpr == NULL) printf("NULL\n");
	while(fpr != NULL){
		FILE* tmpfp = (fpr)->fptr;
		rewind(tmpfp);
		int nc = 0;
		while(!feof(tmpfp)){
			fgets(buf, size, tmpfp);
			int i = 0;
			while(isspace(buf[i++]));
			while(!iscntrl(buf[i])){
				++nc;
				while(isspace(buf[i++]));
			}
		}
		(fpr)->nc = nc;
		printf("%s :c :%d\n", (fpr)->fn, (fpr)->nc);
		(fpr) = (fpr)->next;
	}
}

 void stampa(fnptr fpr, int foundl, int foundw, int foundc){
	int suml = 0, sumw = 0, sumc = 0;
	int single = 0;
	if(fpr->next == NULL) single = 1;
	while(fpr != NULL){
		if(fpr->fptr == NULL){
			printf("mywc: %s: no such file\n", fpr->fn);
			fpr = fpr->next;
			continue;
		}
		if(foundl){
			printf("%d ", fpr->nline);
			suml += fpr->nline;
		}
		if(foundw){
			printf("%d ", fpr->nw);
			sumw += fpr->nw;
		}
		if(foundc){
			printf("%d ", fpr->nc);
			sumc += fpr->nc;
		}
		printf("%s\n", fpr->fn);
		fpr = fpr->next;
	}
	if(!single){
		if(foundl) printf("%d ", suml);
		if(foundw) printf("%d ", sumw);
		if(foundc) printf("%d ", sumc);
		printf("%s\n", "total");
	}
}
int main(int argc, char *argv[])
{
	if(argc < 2){
		perror(argv[0]);
		exit(EXIT_FAILURE);
	}
	char **filename = NULL;
	int size = 0;
	if((size = parsingFilename(&filename, argc, argv)) == 0) {
		perror("filename");
		exit(EXIT_FAILURE);
	}
	//printf("%s %s\n", filename[0], filename[1]);
	fnptr fpr = NULL;
	FILE* tmpf = NULL;
	for (int i = 0; i < size; ++i)
	{
		if((tmpf = fopen(filename[i], "r")) != NULL) insert(&fpr, tmpf, filename[i], 0, 0, 0);
		else insert(&fpr, NULL, filename[i], 0, 0, 0);
	}


	char* buf = (char*)malloc(sizeof(char) * BUFFERSIZE);
	int opt;
	char foundl = 0, foundw = 0, foundc = 0;
	while((opt = getopt(argc, argv, "lwc")) != -1){
		switch(opt){
		case 'l': foundl = 1; arg_l(fpr, buf, BUFFERSIZE); break;
		case 'w': foundw = 1; arg_w(fpr, buf, BUFFERSIZE); break;
		case 'c': foundc = 1; arg_c(fpr, buf, BUFFERSIZE); break;
		case ':': {
			printf("%c richiede un argomento\n", opt); 
		}break;
		case '?': {
			printf("%c non e' riconoscito\n", opt); 
		}break;
		default:;
		}
	}

	if(!foundl && !foundw && !foundc) {
		//printf("l:%d w:%d c:%d\n",foundl,foundw,foundc);
		arg_l(fpr, buf, BUFFERSIZE);
		arg_w(fpr, buf, BUFFERSIZE);
		arg_c(fpr, buf, BUFFERSIZE);
		stampa(fpr, 1, 1, 1);
	}
	else stampa(fpr, foundl, foundw, foundc);

	fptrclose(fpr);
	free(buf);
	for (int i = 0; i < size; ++i)
	{
		free(filename[i]);
	}
	free(filename);
	fnptr tmp = NULL;
	while(fpr != NULL){
		tmp = fpr;
		fpr = fpr->next;
		free(tmp);
	}
	return 0;
}