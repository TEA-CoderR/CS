#include<stdio.h>
#include<stdlib.h>
#include<error.h>
#define dimN 16
#define dimM  8

#define CHECK_PTR_EXIT(p, s)\
	if(p == NULL){			\
		perror(s);			\
		exit(EXIT_FAILURE);	\
	}

#define ELEM(m, i, j) *(m + i*dimM + j)

#define PRINTMAT(m, dn, dm) 					\
	for (int i = 0; i < dn; ++i)				\
	{											\
		for (int j = 0; j < dm; ++j)			\
		{										\
			printf("%ld\t", *(m + i*dimM +j));	\
		}										\
		printf("\n");							\
	}

int main() {
    long *M = malloc(dimN*dimM*sizeof(long));
    CHECK_PTR_EXIT(M, "malloc"); 
    for(size_t i=0;i<dimN;++i)
	for(size_t j=0;j<dimM;++j)			
	    ELEM(M,i,j) = i+j;    
    
    PRINTMAT(M, dimN, dimM);
    free(M);
    return 0;
}