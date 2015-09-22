default rel
global blur_asm
global gauss_matrix

extern malloc
extern free
extern pow

section .data
	tau:	DD 6.28319
	euler:	DD 2.71828
	align 16
	mask_pixel_0_to_int:	DB 0, 128, 128, 128, 1, 128, 128, 128, 2, 128, 128, 128, 3, 128, 128, 128
	mask_int_to_pixel_0:	DB 0, 4, 8, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128
	mask_copy_0_float:		DB 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3

section .text
;void blur_asm    (
	;unsigned char *src, (rdi)
	;unsigned char *dst, (rsi)
	;int filas, (edx)
	;int cols, (ecx)
    ;float sigma, (xmm0)
    ;int radius) (r8d)

blur_asm:
	push rbp
	sub rsp, 8
	push rdx	; filas
	push rcx	; columnas
	push r8		; radio

	mov r12, rdi	; r12 = puntero a imagen original
	mov r13, rsi	; r13 = puntero a imagen destino
	mov r14d, edx
	mov rbp, r8

	mov edi, ebp
	call gauss_matrix
	push rax			; guardo el puntero al inicio de la matriz
	mov rdi, rax		; rdi = matriz convolución

	; Tengo que calcular la posición inicial, que como comienza desde abajo la
	; imagen, tengo que sumarle 2 veces el radio por la cantidad de bytes por fila
	xor r8, r8
	mov r8d, ebp
	shl r8, 1		; r8d = 2*radio

	mov eax, r14d
	shl eax, 2		; edx = filas*4
	xor rbx, rbx
	mov rbx, rax	; rbx = ancho en bytes

	mul r8d
	shl rdx, 32
	mov edx, eax

	lea r12, [r12 + rdx]	; r12 = puntero iterador imagen original
	mov rsi, r12			; rsi = puntero imagen original
	lea r13, [r13 + rdx]	; r13 = puntero iterador imagen destino

	mov r15, r8		; x = 2*radio
	mov r9, r8		; y = 2*radio

	xor r10, r10		; x_m (matriz convolución)
	xor r11, r11		; y_m (matriz convolución)
	pxor xmm10, xmm10	; xmm10 = acum
	inc r8d				; r8d = n = 2*radio+1

	.convolucion:
		; Proceso pixel i
		movd xmm8, [r12]		; xmm8 = px_i
		movd xmm9, [rdi]		; xmm9 = g_i
		movdqu xmm11, [mask_pixel_0_to_int]
		movdqu xmm12, [mask_copy_0_float]

		pshufb xmm8, xmm11	; xmm0 = [alpha|blue|green|red] px_i
		cvtdq2ps xmm8, xmm8
		pshufb xmm9, xmm12
		mulps xmm8, xmm9
		addps xmm10, xmm8

		; Preparo punteros para el siguiente pixel
		lea r12, [r12 + 4]
		lea rdi, [rdi + 4]

		inc r10d	; x_m++
		mov eax, r10d
		xor rdx, rdx
		div r8d		; x_m/n
		cmp edx, 0
		; Si todavía no termine de recorrer la fila de la matriz de convolución, sigo
		jne .convolucion
		inc r11d	; y_m++
		mov r12, rsi

		; Calculo desplazamiento y_m en imagen
		mov eax, r11d
		mul ebx
		shl rdx, 32
		mov edx, eax
		sub r12, rdx

		xor r10, r10	; x_m = 0
		mov eax, r11d
		xor rdx, rdx
		div r8d			; y_m/n
		cmp edx, 0
		; Si todavía no recorrí todas las filas de la matriz de convolución, sigo
		jne .convolucion
		; Terminé la convolución para un pixel, ahora lo guardo
		xor r11, r11		; y_m = 0
		cvtps2dq xmm10, xmm10
		pshufb xmm10, [mask_int_to_pixel_0]
		mov r12, r13		; cargo puntero a pos en imagen
		xor rbp, rbp
		mov ebp, [rsp + 8]	; cargo radio

		mov rax, rbx
		mul rbp
		shl rdx, 32
		mov edx, eax		; radio*bytes por fila

		sub r12, rdx		; r12 - radio*bytes por fila
		shl rbp, 2
		add r12, rbp		; r12 + radio*4 (tamaño de pixel)

		movd [r12], xmm10	; Guardo pixel resultante

		inc r15d			; x++

		pxor xmm10, xmm10	; reinicio acumulador
		mov rdi, [rsp]		; vuelvo al principio de la matriz
		add rsi, 4
		add r13, 4
		mov r12, rsi		; avanzo el puntero de la imagen un pixel

		mov eax, r15d
		xor rdx, rdx
		div dword [rsp + 16]	; x/ancho
		cmp edx, 0
		; Si no terminé de procesar toda la fila de la imagen, sigo
		jne .convolucion
		inc r9d				; y++
		xor rax, rax
		mov eax, [rsp + 8]	; radio
		shl rax, 1			; radio*2
		add r15d, eax		; x = x + 2*radio
		shl rax, 2			; rax = radio*2*4

		add rsi, rax		; le sumo una fila al puntero de la imagen original
		add r13, rax		; le suma una fila al puntero de la imagen destino
		mov r12, rsi

		mov eax, r9d
		xor rdx, rdx
		div dword [rsp + 24]	; y/alto
		cmp edx, 0
		; Si no terminé de procesar todas las filas de la imagen, sigo
		jne .convolucion

	pop rdi		; Libero la memoria usada por la matriz
	call free

	add rsp, 32
	pop rbp
    ret

; rdi, xmm0
gauss_matrix:
	push rbp
	push r12
	push r13
	push r14
	push r15
	sub rsp, 16

	movq xmm1, xmm0	; xmm1 = sigma
	mov r12d, edi	; r12d = radio
	mov r13d, edi
	shl r13, 1		; r13d = 2*radio
	inc r13d		; r13d = n = 2*radio + 1
	mov eax, r13d
	mul r13d
	shl rdx, 32
	mov edx, eax
	shl rdx, 2		; rdx = n*n*4 (float)

	mov rdi, rdx

	movdqu [rsp], xmm1

	call malloc

	movdqu xmm1, [rsp]

	mov rbx, rax	; puntero a matriz
	mov rbp, rax

	xor r14, r14	; x
	xor r15, r15	; y

	.loop:
		mov edi, r14d
		mov esi, r15d
		sub edi, r12d	; x - r
		sub esi, r12d	; y - r
		movq xmm0, xmm1
		movdqu [rsp], xmm1
		call gauss_2d
		movdqu xmm1, [rsp]
		movd [rbx], xmm0	; guardo en la matriz
		lea rbx, [rbx + 4]

		inc r14d	; x++
		mov eax, r14d
		xor rdx, rdx
		div r13d	; x/n
		cmp edx, 0
		jne .loop
		inc r15d		; y++
		xor r14, r14	; x = 0
		mov eax, r15d
		xor rdx, rdx
		div r13d		; y/n
		cmp edx, 0
		jne .loop

	mov rax, rbp

	add rsp, 16
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp
	ret

; rdi, rsi, xmm0
gauss_2d:
	push rbp
	sub rsp, 16

	pxor xmm3, xmm3

	mov eax, edi
	imul edi
	shl rdx, 32
	mov edx, eax
	mov rdi, rdx		; x**2

	mov eax, esi
	imul esi
	shl rdx, 32
	mov edx, eax		; y**2x

	add rdx, rdi		; x**2+y**2

	mulss xmm0, xmm0	; sigma**2
	movd xmm1, [tau]
	mulss xmm1, xmm0	; tau*sigma**2
	movdqu [rsp], xmm1

	xor rax, rax
	mov rax, -2
	cvtsi2ss xmm2, rax
	mulss xmm2, xmm0	; -2*sigma**2

	cvtsi2ss xmm3, rdx
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
