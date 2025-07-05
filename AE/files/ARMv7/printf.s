	.data
	@ questa è la stringa di formato per la printf
ciccio:	.string "Il valore del registro è %d\n"

	.text
	.global main

main: 	mov r2, #123	@ esempio di valori da stampare
	mov r3, #15	@ idem
	
	@ preparazione dei parametri (attuali)
	ldr r0, =ciccio	@ primo parametro in r0: indirizzo della stringa formato
	mov r1, r2 	@ secondo param in r1: valore da sostituire al %d

	bl printf	@ chiamata di funzione: salta a printf e metti
			@ l'indirizzo della prossima istruzione nel LR

	mov r1, r3	@ quando la printf torna esegui questa
	bl printf 	@ se richiamo la printf ottengo un errore (SEGV)
			@ perche' r0 ora contiene il valore restituito dalla
			@ precedente chiamata printf (# di caratteri stampati)
			@ Questo viene interpretato come indirizzo di memoria
			@ e la parte bassa della memoria (r0 vale 30 qui)
			@ non appartiene al mio spazio di indirizzamento

	mov r7, #1      @ implementano una syscall exit(r0)
	svc 0 
