	.data
fmt:	.string "Il fattoriale vale %d\n"
	.text
	.global main

main: 	push {lr}
	mov r0, #4
	bl fact

	mov r1, r0
	ldr r0, =fmt
	bl printf
	
	pop {lr}
	bx lr

fact: 	push {lr}
	mov r1, #1 	@ init acc
	bl fact1	@ r0 = n, r1 = acc
	pop {pc}	@ e ritorna

fact1: 	cmp r0, #1
	moveq r0, r1	@ se n = 1 restituisci acc
	moveq pc, lr 	@ e ritorna
	mul r1, r1, r0	@ acc = acc * n
	sub r0, r0, #1  @ n = n - 1
	b fact1
