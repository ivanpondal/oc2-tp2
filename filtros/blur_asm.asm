default rel
global _blur_asm
global blur_asm


extern pow

section .data
	align 16
	tau:	DQ 6.28318530718
	euler:	DQ 2.71828182845

section .text
;void blur_asm    (
	;unsigned char *src,
	;unsigned char *dst,
	;int filas,
	;int cols,
    ;float sigma,
    ;int radius)

_blur_asm:
blur_asm:


    ret

; rdi, rsi, xmm0
gauss_2d:
	push rbp
	mov rbp, rsp
	sub rsp, 16

	mov eax, edi
	imul edi
	and rax, 0x0000FFFF
	shl rdx, 32
	or rax, rdx
	mov rdi, rax		; x**2

	mov eax, esi
	imul esi
	and rax, 0x0000FFFF
	shl rdx, 32
	or rax, rdx			; y**2

	add rax, rdi		; x**2+y**2

	mulsd xmm0, xmm0	; sigma**2
	movq xmm1, [tau]
	mulsd xmm1, xmm0	; tau*sigma**2
	movdqu [rsp], xmm1

	xor rdx, rdx
	mov rdx, -2
	cvtsi2sd xmm2, rdx
	mulsd xmm2, xmm0	; -2*sigma**2

	cvtsi2sd xmm3, rax
	divsd xmm3, xmm2	; -(x**2+y**2)/(2*sigma**2)

	movq xmm0, [euler]
	movq xmm1, xmm3
	call pow			; e**(-(x**2+y**2)/(2*sigma**2))
	movdqu xmm1, [rsp]

	divsd xmm0, xmm1	; (e**(-(x**2+y**2)/(2*sigma**2)))/(tau*sigma**2)

	add rsp, 16
	pop rbp
	ret
