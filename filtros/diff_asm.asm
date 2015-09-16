default rel
global _diff_asm
global diff_asm


section .data
	mask_r: db 0xd, 0xd, 0xd, 0xc, 0x9, 0x9, 0x9, 0x8, 0x5, 0x5, 0x5, 0x4, 0x1, 0x1, 0x1, 0x0

section .text
;void diff_asm    (
	;unsigned char *src,		;rsi
   ;unsigned char *src2,	;rdi
	;unsigned char *dst,		;rdx
	;int filas,					;ecx
	;int cols)					;r8d

_diff_asm:
diff_asm:
	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14

	mov r12, rsi			;r12 = src
	mov r13, rdi			;r13 = src2
	mov r14, rdx 			;r14 = dst

	;Calculo la cantidad de pixeles total
	xor rax, rax
	xor rdx, rdx
	mov eax, ecx
	mul r8d					;eax = low(filas*cols) ;edx = high(filas*cols)
	shl rdx, 32
	add rax, rdx			;rax = #pixeles

	;Inicializo el contador
	mov rcx, rax
	shr rcx, 2				;Proceso de a 4 pixeles

	;Itero sobre todos los pixeles y realizo l operación de diff
	.ciclo:
		movdqu xmm1, [r12]	;xmm1 = px3 | px2 | px1 | px0
		movdqu xmm2, [r13]	;xmm2 = px3'| px2'| px1'| px0'
		;Antes de restar necesito desempaquetar de bytes a words, pues el resultado puede ser negativo, y por tanto requiero el doble de bits
		pxor xmm7, xmm7
		movdqu xmm3, xmm1
		movdqu xmm4, xmm2
		punpcklbw xmm1, xmm7	;xmm1 = (b1,g1,r1,a1) | (b0,g0,r0,a0)
		punpckhbw xmm3, xmm7	;xmm3 = (b3,g3,r3,a3) | (b2,g2,r2,a2)
		punpcklbw xmm2, xmm7	;xmm2 = (b1',g1',r1',a1') | (b0',g0',r0',a0')
		punpckhbw xmm4, xmm7	;xmm4 = (b3',g3',r3',a3') | (b2',g2',r2',a2')
		
		psubb xmm1, xmm2 		;xmm1 = (b1-b1',...,a1-a1')| (b0-b0',...,a0-a0')
		psubb xmm3, xmm4 		;xmm3 = (b3-b3',...,a3-a3')| (b2-b2',...,a2-a2')
		pabsw xmm1, xmm1		;xmm1 = (|b1-b1'|,...,|a1-a1'|) | (|b0-b0'|,...,|a0-a0'|)
		pabsw xmm3, xmm3		;xmm3 = (|b3-b3'|,...,|a3-a3'|) | (|b2-b2'|,...,|a2-a2'|)
		packuswb xmm1, xmm3	;xmm1 = (|b3-b3'|,...,|a3-a3'|) |...| (|b0-b0'|,...,|a0-a0')

		;Ahora calculo el máximo
		movdqu xmm2, xmm1
		psrld xmm2, 4			;xmm2 = (0,|b3-b3'|,...,|r3-r3'|) |...| (0,|b0-b0'|,...,|r0-r0'|)
		pmaxub xmm2, xmm1
		psrld xmm2, 4
		pmaxub xmm2, xmm1		;el máximo de cada pixel esta en la componente r

		pshufb xmm2, [mask_r]
		movdqu [r14], xmm2

		;Avanzo los punteros
		add r12, 16
		add r13, 16
		add r14, 16
		loop .ciclo
	
	pop r14	
	pop r13
	pop r12	
	pop rbp
   ret
