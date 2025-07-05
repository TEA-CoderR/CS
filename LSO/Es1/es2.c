#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
 
const int REALLOC_INC=16;
 
void RIALLOCA(char** buf, size_t newsize) {
  *buf = (char*)realloc(*buf, newsize); 
  if(!*buf){
    printf("realloc: MEMORIA ESAURITA, esco\n");
    exit(-1);
  }
}     

char* mystrcat(char *buf, size_t sz, char *first, ...) {
  va_list list;
  va_start(list, first);
  if(sz < strlen(first) + 1){
      RIALLOCA(&buf, sz + strlen(first) + 1 + REALLOC_INC);
      sz += strlen(first) + 1 + REALLOC_INC;
  }
  strncat(buf, first, sz);

  char *arg = NULL;
  while((arg = va_arg(list, char*)) != NULL){
    int lenBuf = strlen(buf);
    int lenArg = strlen(arg);
    if(sz < lenBuf + lenArg + 1){
      RIALLOCA(&buf, lenBuf + lenArg + 1 + REALLOC_INC);
      sz = lenBuf + lenArg + 1 + REALLOC_INC;
    }
    strncat(buf, arg, sz);
    //printf("%s\n", buf);
  }
  va_end(list);

  return buf;
}  
 
int main(int argc, char *argv[]) {
  if (argc < 7) { printf("troppi pochi argomenti\n"); return -1; }
  char *buffer=NULL;
  RIALLOCA(&buffer, REALLOC_INC);  // macro che effettua l'allocazione del 'buffer'
  buffer[0]='\0'; // mi assicuro che il buffer contenga una stringa
  buffer = mystrcat(buffer, REALLOC_INC, argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], NULL);
  printf("%s\n", buffer);   
  //printf("%s\n", mystrcat(buffer, strlen(buffer), "prima stringa", "seconda", "terza molto molto molto lunga", "quarta", "quinta lunga", "ultima!",NULL));
  
  free(buffer);
  return 0;
}