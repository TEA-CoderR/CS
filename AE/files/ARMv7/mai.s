	.data 
	@@@@@@@@ stringa in input @@@@@@
str:	.string "Questa non e' Maiuscola"
	@@@@@@@@ formato printf   @@@@@@
fmt: 	.string "String = <%s>\n"

	.text
	.global main

main: 	ldr r0, =fmt	@ stampa la stringa iniziale
	ldr r1, =str
	bl printf

	ldr r1, =str	@ va ricaricato perchè la chiamata di funzione non lo conserva
loop: 	ldrb r2, [r1]	@ carica codice ASCCI
	cmp r2, #0	@ null terminated string => se è 0 vuol dire che la string è finita
	beq fine

	cmp r2, #0x61	@ se è < 'a' passa al prossimo carattere
	blt next
	cmp r2, #0x7a	@ se è > 'z' passa al prossimo carattere
	bgt next
	sub r2, r2,#0x20	@ altrimenti togli 'a'-'A' (le maiuscole hanno codici più bassi)
	strb r2, [r1]	@ e rimetti il nuovo codice al suo posto

next:	add r1,r1,#1	@ per il prossimo carattere l'indirizzo aumenta di 1 (bytes)
	b loop

fine:	ldr r0, =fmt	@ se hai finito stampa la (nuova) stringa
	ldr r1, =str
	bl printf

	mov R7, #1
	svc 0
