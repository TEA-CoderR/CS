	.data 
strbuf:	.fill 1024	@spazio per stringa da 1024 caratteri
fmt: 	.string "String = <%s>\n"

	.text
	.global main

main:	mov r0, #0 	@ descrittore stdin (0 stdin, 1 stdout, 2 stderr)
	ldr r1, =strbuf	@ indirizzo del buffer (&buffer)
	mov r2, #1	@ lunghezza della stringa (non posso utilizzare più
	lsl r2, r2, #9  @ di 8 bit per la costante, dunque uso 1 << 9)

	mov r7, #3	@ la syscall read è la numero 3 (vedi tabella)
	svc 0		@ invoca la syscall read(stdin,&buffer,1024)
	mov r3, r0	@ la syscall restituisce il numero di caratteri letti
	sub r3, r3, #1	@ togliamo 1 per non contare il \n finale 
	mov r2, #0      @ NULL -> R2
	ldr r1, =strbuf @ indirizzo base della stringa letta
	strb r2, [r1,r3]@ metti NULL al posto del \n finale 
	
	ldr r0, =fmt	@ stampa la stringa iniziale
	ldr r1, =strbuf @ con una printf 
	bl printf       @ per controllo 

	ldr r1, =strbuf	@ va ricaricato perchè la chiamata di funzione non lo conserva
loop: 	ldrb r2, [r1]	@ carica codice ASCCI
	cmp r2, #0	@ null terminated string => se è 0 vuol dire che la string è finita
	beq fine	@ in questo caso andiamo alla fine e stampiamo la stringa trasformata

	cmp r2, #0x61	@ trasformiamo solo i car in 'a'-'z'
	blt next	@ se non è una minuscola di sicuro, andiamo a vedere il prossimo carattere 
	cmp r2, #0x7a	@ trasformiamo solo i car in 'a'-'z'
	bgt next	@ se non è una minuscola di sicuro, andiamo a vedere il prossimo carattere 
	sub r2, r2,#0x20@ altrimenti togli 'a'-'A' (le maiuscole hanno codici più bassi)
	strb r2, [r1]	@ e rimetti il nuovo codice al suo posto

next:	add r1,r1,#1	@ per il prossimo carattere l'indice aumenta di 1 (indirizziamo bytes)
	b loop		@ e ricominciamo caricando il prossim carattere 

fine:	ldr r0, =fmt	@ se hai finito stampa la (nuova) stringa
	ldr r1, =strbuf @ utilizzando la solita printf 
	bl printf

	mov R7, #1	@ syscall 1 => exit
	mov r0, #0	@ exit(0), visto che siamo arrivati in fondo bene
	svc 0		@ chiama la exit(0)
