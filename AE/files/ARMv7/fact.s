	.text
	.global main

	@ indirizzo di argv in r1
	@ primo parametro in argv[1] ovvero ldr _, [r1, #4]

main:	mov r0, #4		@ fattoriale di 4 = 4 * 3 * 2 * 1 = 24
	bl fact			@ chiamata di funzione
	mov r7, #1		@ exit(ris)
	svc 0 

	@ riusciamo a fare tutto coi registri temporanei, dunque non occorre
  	@ usare r4-r12, che andrebbero salvati anche loro sullo stack e 
	@ ripristinati prima di tornare ... 

			@ questo è l'entry point della proc ricersiva
fact: 	cmp r0, #1	@ controlla che non sia il caso base (fact(1) = 1)
	bne ric		@ se non caso base, esegui chiamata ricorsiva
	mov PC, LR	@ altrimenti restituisci 1 (e' gia' in R0)

ric:	push {r0,LR}	@ salva n e indirizzo di ritorno
	sub r0, r0, #1	@ calcola n-1
	bl fact	  	@ chiamata ricorsiva (fact(n-1)) -> R0 
	pop {r1,LR}	@ ripristina n e indirizzo di ritorno (n -> r1 !!) 
	mul r0, r1, r0	@ calcola n * fact(n-1)  -> R0 
	mov PC, LR	@ e ritorna (restituisce R0 come valore)

	
