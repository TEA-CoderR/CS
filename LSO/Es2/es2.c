#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<unistd.h>

//#typedef int F_t(char*)

int isNumber(char *s, long *narg){
  char *e =NULL;
  *narg = strtol(s,&e,0);
  if(e != NULL && *e ==(char)0) return 1;
  return 0;
}

int parsingN(char *optarg){
  long narg = -1;
  if(!isNumber(optarg, &narg)) return -1;
  printf("-n %ld\n", narg);
  return 0;
}
int parsingS(char *optarg){
  char *sarg = NULL;
  if((sarg = strdup(optarg)) == NULL){
    printf("MEMORIA EUSARITA\n");
    return -1;
  }
  printf("-o %s\n", sarg);
  return 0;
}

int printfUsage(char *program){
  printf("Usage :%s -f <num> -g<string> -h\n", program);
  exit(-1);
}
int main(int argc, char* argv[]) {
 
  int (*V[3])(char *) = {parsingN,parsingS,printfUsage};
  int opt;
  while ((opt = getopt(argc,argv, "f:g:h")) != -1) {
    switch(opt) {
    case '?': { 
       printf("%c :unknown argoment\n", opt);
       exit(-1);
    } break;
    default:
     // invocazione della funzione di gestione passando come parametro l'argomento restituito da getopt
     printf("opt :%c,optarg :%s, optdiv3 :%d\n", opt, optarg, opt%3);
     if (V[opt%3]( (optarg==NULL ? argv[0] : optarg) ) == -1) {
      printf("%c :argoment non valido\n", opt);
      exit(-1);
     }
    }
  }
  return 0; 
}