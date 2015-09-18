default rel
global _diff_asm
global diff_asm


section .data
	align 16
	end_255: db 0xff, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	align 16
	;mask_r: db 1,1,0,1,5,5,0,5,9,9,0,9,13,13,0,13 
	mask_r: db 2,2,2,0,6,6,6,0,10,10,10,0,14,14,14,0  
	;el orden efectivamente es b,g,r,a

section .text
;void diff_asm    (
	;unsigned char *src,		;rsi
   	;unsigned char *src2,		;rdi
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

	;Itero sobre todos los pixeles y realizo la operación de diff
	.ciclo:
		movdqu xmm1, [r13]	;xmm1 = px3 | px2 | px1 | px0
		movdqu xmm2, [r12]	;xmm2 = px3'| px2'| px1'| px0'
		;Antes de restar necesito desempaquetar de bytes a words, pues el resultado puede estar entre -255 y 255, y por tanto requiero el doble de bits
		pxor xmm7, xmm7
		movdqu xmm3, xmm1
		movdqu xmm4, xmm2
		punpcklbw xmm1, xmm7	;xmm1 = (b1,g1,r1,a1) | (b0,g0,r0,a0)
		punpckhbw xmm3, xmm7	;xmm3 = (b3,g3,r3,a3) | (b2,g2,r2,a2)
		punpcklbw xmm2, xmm7	;xmm2 = (b1',g1',r1',a1') | (b0',g0',r0',a0')
		punpckhbw xmm4, xmm7	;xmm4 = (b3',g3',r3',a3') | (b2',g2',r2',a2')
		
		psubw xmm1, xmm2 		;xmm1 = (a1-a1',...,b1-b1')| (a0-a0',...,b0-b0')
		psubw xmm3, xmm4 		;xmm3 = (a3-a3',...,b3-b3')| (a2-a2',...,b2-b2')
		pabsw xmm1, xmm1		;xmm1 = (|a1-a1'|,...,|b1-b1'|) | (|a0-a0'|,...,|b0-b0'|)
		pabsw xmm3, xmm3		;xmm3 = (|a3-a3'|,...,|b3-b3'|) | (|a2-a2'|,...,|b2-b2'|)
		packuswb xmm1, xmm3		;xmm1 = (|a3-a3'|,...,|b3-b3'|) |...| (|a0-a0'|,...,|b0-b0')

		;Ahora calculo el máximo
		movdqu xmm2, xmm1
		pslld xmm2, 8			;xmm2 = (|r3-r3'|,...,|b3-b3'|,0) |...| (|r0-r0'|,...,|b0-b0'|,0)
		pmaxub xmm2, xmm1		
		pslld xmm2, 8
		pmaxub xmm2, xmm1		;el máximo de cada pixel esta en la componente r
		por xmm2, [end_255]
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
