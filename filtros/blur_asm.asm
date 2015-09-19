default rel
global _blur_asm
global blur_asm
global gauss_matrix

extern malloc
extern pow

section .data
	align 16
	tau:	DD 6.28319
	euler:	DD 2.71828

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

; rdi, xmm0
gauss_matrix:
	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14
	push r15
	sub rsp, 32

	movq xmm1, xmm0	; sigma
	mov r12w, di	; radius
	mov r13w, di
	shl r13w, 1		; 2*radius
	inc r13w		; n = 2*radius + 1
	mov ax, r13w
	xor rdx, rdx
	mul r13w
	and rax, 0x000000FF
	shl rdx, 16
	or rax, rdx
	shl rax, 2		; n*n*4 (float)

	mov rdi, rax

	movdqu [rsp], xmm1

	call malloc

	movdqu xmm1, [rsp]

	mov rbx, rax	; puntero a matriz
	mov rbp, rax

	xor r14, r14	; x
	xor r15, r15	; y
	pxor xmm2, xmm2	; acumulador

	.loop:
		mov di, r14w
		mov si, r15w
		sub di, r12w	; x - r
		sub si, r12w	; y - r
		movq xmm0, xmm1
		movdqu [rsp], xmm1
		movdqu [rsp+16], xmm2
		call gauss_2d
		movdqu xmm2, [rsp+16]
		movdqu xmm1, [rsp]
		addss xmm2, xmm0	; sumo al acumulador
		movd [rbx], xmm0	; guardo en la matriz
		lea rbx, [rbx + 4]

		inc r14w	; x++
		mov ax, r14w
		xor rdx, rdx
		div r13w	; x/n
		cmp dx, 0
		jne .loop
		inc r15w		; y++
		xor r14, r14	; x = 0
		mov ax, r15w
		xor rdx, rdx
		div r13w		; y/n
		cmp dx, 0
		jne .loop

	mov rax, rbp

	add rsp, 32
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp
	ret

; rdi, rsi, xmm0
gauss_2d:
	push rbp
	mov rbp, rsp
	sub rsp, 16

	pxor xmm3, xmm3

	mov ax, di
	imul di
	and rax, 0x000000FF
	shl rdx, 16
	or rax, rdx
	mov edi, eax		; x**2

	mov ax, si
	imul si
	and rax, 0x000000FF
	shl rdx, 16
	or rax, rdx			; y**2

	add eax, edi		; x**2+y**2

	mulss xmm0, xmm0	; sigma**2
	movd xmm1, [tau]
	mulss xmm1, xmm0	; tau*sigma**2
	movdqu [rsp], xmm1

	xor rdx, rdx
	mov rdx, -2
	cvtsi2ss xmm2, rdx
	mulss xmm2, xmm0	; -2*sigma**2

	cvtsi2ss xmm3, eax
	divss xmm3, xmm2	; -(x**2+y**2)/(2*sigma**2)

	movd xmm0, [euler]
	movq xmm1, xmm3
	cvtss2sd xmm0, xmm0
	cvtss2sd xmm1, xmm3
	call pow			; e**(-(x**2+y**2)/(2*sigma**2))
	cvtsd2ss xmm0, xmm0
	movdqu xmm1, [rsp]

	divss xmm0, xmm1	; (e**(-(x**2+y**2)/(2*sigma**2)))/(tau*sigma**2)

	add rsp, 16
	pop rbp
	ret
