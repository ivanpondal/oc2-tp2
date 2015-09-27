; RECORDATORIOS
; inputs: rdi, rsi, rdx, rcx, r8, r9
; preservar: r12, r13, r14, r15, rbx, 
; la pila: rbp, rsp
; devolver cosas por rax o xmmo 
; inputs floats: xmm0, xmm1, ..., xmm7

default rel
global blur_asm
global gauss_matrix

extern kernel_impreciso_ushort
extern kernel_impreciso_uint
extern g_sigma
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
	
	mask_pixel_0_to_short:	DB 0, 128, 1, 128, 2, 128, 3, 128, 8, 128, 9, 128, 10, 128, 11, 128
	mask_pixel_1_to_short:	DB 0, 128, 1, 128, 2, 128, 3, 128, 128, 128, 128, 128, 128, 128, 128, 128
	mask_copy_0:			DB 0, 1, 0, 1, 0, 1, 0, 1, 8, 9, 8, 9, 8, 9, 8, 9
	mask_copy_1:			DB 0, 1, 0, 1, 0, 1, 0, 1, 128, 128, 128, 128, 128, 128, 128, 128
	mask_short_to_pixel_0:	DB 8, 10, 12, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128


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

	; Llamo a la versión de implementación con la que quiero experimentar
	;call blur_asm_v1
	;call blur_asm_v2
	call blur_asm_v3

	pop rbp
	ret

; Implementación operando con float
blur_asm_v1:
	push rbp
	mov rbp,rsp
	pop r12
	pop r13
	pop r14
	pop r15
	pop rbx	
	sub rsp, 8
	push rdx	; filas
	push rcx	; columnas
	push r8		; radio

	mov r12, rdi	; r12 = puntero a imagen original
	mov r13, rsi	; r13 = puntero a imagen destino
	mov r14d, edx	; r14d = filas
	mov rbp, r8		; rbp = radio

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
	shl eax, 2		; eax = filas*4 ;me parece que esta mal eso, deberia ser cols*4
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
	pop rbx
	pop r15
	pop r14
	pop r13
	pop r12
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

; Implementación operando con unsigned int
blur_asm_v2:
	push rbp
	mov rbp,rsp
	pop r12
	pop r13
	pop r14
	pop r15
	pop rbx	
	sub rsp, 8
	push rdx	; filas
	push rcx	; columnas
	push r8		; radio

	mov r12, rdi	; r12 = puntero a imagen original
	mov r13, rsi	; r13 = puntero a imagen destino
	mov r14d, ecx	; r14d = columnas
	mov r15d, r8d	; r15d = radio
	

	mov ecx, r15d	; ecx = radio
	shl rcx, 1		; ecx = radio*2
	add rcx, 1		; ecx = radio*2+1
	mov ebx,ecx		; ebx = radio*2+1
	mov eax, ecx
	mul ecx			; eax = (radio*2+1)^2 = n
	shl rdx, 32
	mov edx, eax
	shl rdx, 2		; rdx = n*n*4 (float)

	mov rdi,rdx
	
	call malloc
	push rax		; guardo el puntero al inicio del kernel

	xor rdi,rdi
	mov edi, ebx	; antes de llamar a kernel paso n = 2*radio+1
	xor rsi,rsi
	mov esi, r15d	; antes de llamar a kernel paso el radio
	mov rdx, rax	; antes de llamar a kernel paso el puntero a la matriz
	
	call kernel_impreciso_uint
	pop	 rdi		; rdi = puntero al kernel
	push rdi		; vuelvo a guardar en la pila el puntero al kernel

	xor rcx,rcx
	mov ecx,eax 	; ecx = exponente de la potencia de 2

	; Tengo que calcular la posición inicial, que como comienza desde abajo la
	; imagen, tengo que sumarle 2 veces el radio por la cantidad de bytes por fila
	xor r8, r8
	mov r8d, r15d
	shl r8, 1		; r8d = 2*radio

	mov eax, r14d
	shl eax, 2		; eax = cols*4
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
		pshufb xmm9, xmm12
		PMULLD xmm8, xmm9
		PADDD xmm10, xmm8 ;probar con PADDUSB o PADDD

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

		pxor xmm5,xmm5
		vmovq xmm5,rcx
		PSRLD xmm10,xmm5
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
	pop rbx	
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp
    ret

; Implementación operando con unsigned short
blur_asm_v3:
	push rbp
	mov rbp,rsp
	pop r12
	pop r13
	pop r14
	pop r15
	pop rbx	
	sub rsp, 8
	push rdx	; filas
	push rcx	; columnas
	push r8		; radio

	mov r12, rdi	; r12 = puntero a imagen original
	mov r13, rsi	; r13 = puntero a imagen destino
	mov r14d, ecx	; r14d = columnas
	mov r15d, r8d	; r15d = radio
	

	mov ecx, r15d	; ecx = radio
	shl rcx, 1		; ecx = radio*2
	add rcx, 1		; ecx = radio*2+1
	mov ebx,ecx		; ebx = radio*2+1
	mov eax, ecx
	mul ecx			; eax = (radio*2+1)^2 = n
	shl rdx, 32
	mov edx, eax
	shl rdx, 1		; rdx = n*n*2

	mov rdi,rdx
	
	call malloc
	push rax		; guardo el puntero al inicio del kernel

	xor rdi,rdi
	mov edi, ebx	; antes de llamar a kernel paso n = 2*radio+1
	xor rsi,rsi
	mov esi, r15d	; antes de llamar a kernel paso el radio
	mov rdx, rax	; antes de llamar a kernel paso el puntero a la matriz
	
	call kernel_impreciso_ushort
	pop	 rdi		; rdi = puntero al kernel
	push rdi		; vuelvo a guardar en la pila el puntero al kernel

	xor rcx,rcx
	mov ecx,eax 	; ecx = exponente de la potencia de 2

	; Tengo que calcular la posición inicial, que como comienza desde abajo la
	; imagen, tengo que sumarle 2 veces el radio por la cantidad de bytes por fila
	xor r8, r8
	mov r8d, r15d
	shl r8, 1		; r8d = 2*radio

	mov eax, r14d
	shl eax, 2		; eax = cols*4
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
	shr r8,1			; r8d = radio

	xor r14,r14			
	mov r14d,r8d		; r14d = radio
	

	inc r8d				; r8d = radio + 1
	
	.convolucion:

		; Proceso pixel_i y pixel_i+1		
		
		cmp r10d,r14d			; ¿estoy en el ultimo elemento de la fila del kernel?
		je .ultimofila
		movd xmm8, [r12]		; xmm8 = px_i
		PSLLDQ xmm8,8
		lea r12, [r12 + 4]
		movd xmm8, [r12]		; xmm8 = | 0 | 0 | px_i | 0 | 0 | px_i+1|

		movd xmm9, [rdi]		; xmm9 = g_i
		PSLLDQ xmm9,8
		lea rdi, [rdi + 2]
		movd xmm9, [rdi]		; xmm9 = | 0 | 0 | 0 | g_i | 0 | 0 | 0 | g_i+1 |
		
		movdqu xmm11, [mask_pixel_0_to_short] ; Una mitad con g_i y la otra con g_i+1
		movdqu xmm12, [mask_copy_0] ; Una mitad con un pixel y la otra con el siguiente

		pshufb xmm8, xmm11	; xmm8 = [alpha_i|blue_i|green_i|red_i|alpha_i+1|blue_i+1|green_i+1|red_i+1]
		pshufb xmm9, xmm12	; xmm9 = [g_i	|g_i	|g_i	|g_i	|g_i+1	|g_i+1	|g_i+1	|g_i+1	]	
		PMULLW xmm8, xmm9	; xmm8 = producto entre los de arriba
		PADDW xmm10, xmm8

		jmp .sigo

		.ultimofila:
		; Proceso pixel i y pixel_i+1
		movd xmm8, [r12]		; xmm8 = px_i
		push r9
		xor r9,r9
		mov r9w,[rdi]
		movd xmm9, r9d		; xmm9 = g_i
		pop r9
		movdqu xmm11, [mask_pixel_1_to_short] ; <-- mitad baja con pixels pasados a short
		movdqu xmm12, [mask_copy_1] ; <-- mitad baja con 4 g_is

		pshufb xmm8, xmm11	; xmm8 = [ 0 | 0 | 0 | 0 |alpha_i|blue_i|green_i|red_i]
		pshufb xmm9, xmm12	; xmm9 = [ 0 | 0 | 0 | 0 | g_i | g_i | g_i | g_i ]
		PMULLW xmm8, xmm9	; xmm8 = producto entre los de arriba
		PADDW xmm10, xmm8

		.sigo:
		
		;preparo los punteros para la siguiente iteracion
		lea r12, [r12 + 4]
		lea rdi, [rdi + 2]


		inc r10d	; x_m++

		xor r8,r8
		mov r8d,r14d	;r8d = radio
		inc r8d			; r8d = radio+1

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

		shl r8d,1		; r8d = 2*radio + 2
		sub r8d,1		; r8d = 2*radio + 1


		xor r10, r10	; x_m = 0
		mov eax, r11d
		xor rdx, rdx
		div r8d			; y_m/n

		cmp edx, 0

		; Si todavía no recorrí todas las filas de la matriz de convolución, sigo
		jne .convolucion
		; Terminé la convolución para un pixel, ahora lo guardo

		inc r8d			; r8d = 2*radio + 2
		shr r8d,1		; r8d = radio + 1


		xor r11, r11		; y_m = 0

		MOVDQU xmm7,xmm10
		PSLLDQ xmm7,8
		PADDW xmm10, xmm7

		pxor xmm5,xmm5
		vmovq xmm5,rcx
		PSRLW xmm10,xmm5
		pshufb xmm10, [mask_short_to_pixel_0] ;agarro los 4 words que estan en la parte alta y los paso a 4 byte en la parte baja

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
	pop rbx
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp
    ret

