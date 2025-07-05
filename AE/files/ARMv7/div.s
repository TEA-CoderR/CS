	.text
	.globl main
main:	mov r1,#7	@ dividi 7
	mov r2,#3	@ per 3
	mov r0,#0	@ azzera il risultato
loop:	cmp r1,r2
	blt end
	sub r1, r1, r2 	@ togli una volta
	add r0, r0, #1 	@ incrementa risultato
	b loop
@ programma finito, impacco i risultati in un solo registro 
end:	lsl r0, r0, #4	@ sposto il risultato nella prima metà del registro
	orr r0, r0, r1	@ e metto nella parte bassa il resto
	mov r7, #1	@ poi chiamo la exit(r0)
	svc 0
