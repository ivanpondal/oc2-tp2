#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "../tp2.h"

// Constante con número de versión de implementación a usar
#define IMP_BLUR_C 1

void blur_c_v1(unsigned char *src, unsigned char *dst, int cols, int filas, float sigma, int radius);
void blur_c_v2(unsigned char *src, unsigned char *dst, int cols, int filas, float sigma, int radius);

float g_sigma(float sigma, int x, int y){
	//aplico la funcion de densidad guassiana a los parametros
	return (exp(-(x*x+y*y)/(2*sigma*sigma)))/(2*(PI)*sigma*sigma);
}

float* kernel_matrix(float sigma, int radio){
	int m = 2*radio + 1;
	float *k = malloc(m*m*sizeof(float));

	for(int y = 0; y < m; y++){
		for(int x = 0; x < m; x++){
			k[y*m + x] = g_sigma(sigma, x - radio, y - radio);
		}
	}
	return k;
}

void blur_c(unsigned char *src, unsigned char *dst, int cols, int filas, float sigma, int radius){
	switch(IMP_BLUR_C){
		case 1:
			blur_c_v1(src, dst, cols, filas, sigma, radius);
			break;
		case 2:
			blur_c_v2(src, dst, cols, filas, sigma, radius);
			break;
	}
}


// Implementación usando el kernel como matriz
void blur_c_v2(unsigned char *src, unsigned char *dst, int cols, int filas, float sigma, int radius){
	int bytes_in_row = cols*4;
	int m = 2*radius + 1;
	unsigned char (*src_matrix)[bytes_in_row] = (unsigned char (*)[bytes_in_row]) src;
	unsigned char (*dst_matrix)[bytes_in_row] = (unsigned char (*)[bytes_in_row]) dst;
	float (*k)[m] = (float (*)[m]) kernel_matrix(sigma, radius);

	for (int y = radius; y < filas-radius; y++){
		for (int x = 4*radius; x < bytes_in_row-4*radius; x += 4){
			float red = 0;
			float green = 0;
			float blue = 0;
			for(int y_m = 0; y_m < m; y_m++){
				for(int x_m = 0; x_m < m; x_m++){
					red += k[y_m][x_m]*src_matrix[y + y_m - radius][x + 4*(x_m - radius) + RED_OFFSET];
					green += k[y_m][x_m]*src_matrix[y + y_m - radius][x + 4*(x_m - radius) + GREEN_OFFSET];
					blue += k[y_m][x_m]*src_matrix[y + y_m - radius][x + 4*(x_m - radius) + BLUE_OFFSET];
				}
			}
			dst_matrix[y][x + RED_OFFSET] = red;
			dst_matrix[y][x + GREEN_OFFSET] = green;
			dst_matrix[y][x + BLUE_OFFSET] = blue;
		}
	}

	free(k);
}

// Implementación usando el kernel como vector
void blur_c_v1    (
    unsigned char *src,
    unsigned char *dst,
    int cols,
    int filas,
    float sigma,
    int radius)
{

	double excedente = 0;

//Esta es una posible mejora, es para que el kernel sume 1 pero enrealidad no es tan notorio el cambio porque ya suma casi 1
/*
	double g_acum;
//calculo cada rectangulo de cada extremo del kernel

	for(int i = 0; i < radius; i++){
		for(int j = 0; j < radius; j++){
			g_acum = g_acum + g_sigma(sigma, radius - i , radius - j);		
			}
	}
	g_acum = g_acum*4;
//calculo la cruz del kernel formada por la fila y la columna central
	for(int i = 0; i < radius; i++){
		g_acum = g_acum + g_sigma(sigma, radius - i, 0)*4;
	}
	g_acum = g_acum + g_sigma(sigma, 0, 0);

	double radius_d = radius;

	excedente = (1-g_acum)/((2*radius_d+1)*(2*radius_d+1));
*/

    unsigned char (*src_matrix)[cols*4] = (unsigned char (*)[cols*4]) src;
    unsigned char (*dst_matrix)[cols*4] = (unsigned char (*)[cols*4]) dst;


//Guardo los elementos del kernel que voy a necesitar luego	
	int n = (radius+1)*(radius+2)/2;
//Dado un kernel de r vecinos los numeros se repiten de la siguiente manera:
//Para 0, 1, 2, 3 ... r vecinos
//Hay: 1, 3, 6, 10... (r+1)(r+2)/2 numeros sin contar repetidos y estos se hayan en 1/8 de la matriz
	double kernel_vector[n];	

	int contador = 0;
	for(int i = 0; i <= radius; i++){			
		for(int j=i; j <= radius; j++){
			kernel_vector[contador] = g_sigma(sigma, j, i);
			contador++;
		}
	}
	
	int pos_i = radius; // arranco abajo, en la posicion radius contando de abajo hacia arriba
	int pos_j = cols - radius - 1; // arranco a radius distancia del extremo derecho

	double blue_acum;
	double red_acum;
	double green_acum;
	
	double suma_blue;
	double suma_red;
	double suma_green;

	for(int contador = 0; contador < (cols*filas - 2*radius*(cols + filas) + 2*radius*radius); contador++ ){
// (cols*filas - 2*radius*(cols + filas) + 2*radius*radius) es la cantidad de pixels que tengo que cambiar
// Si altero mas pixels que esos me voy a ir muy al borde de la imagen y al querer agarrar elementos a radio distancia van a haber problemas
		blue_acum = 0;
		red_acum = 0;
		green_acum = 0;
		
		for(int i = 0; i <= radius; i++){			
			for(int j=i; j <= radius; j++){
				if(j==0 && i == 0){
					blue_acum = blue_acum + ((unsigned char) src_matrix[pos_i][4*(pos_j) + 0])*(kernel_vector[0] + excedente);
					green_acum = green_acum + ((unsigned char) src_matrix[pos_i][4*(pos_j) + 1])*(kernel_vector[0] + excedente);
					red_acum = red_acum + ((unsigned char) src_matrix[pos_i][4*(pos_j) + 2])*(kernel_vector[0] + excedente);				
				}
				else { 
					if(j==0 || i == 0){
							if(j != 0){
								
								suma_blue = (src_matrix[pos_i][4*(pos_j + j) + 0] + src_matrix[pos_i][4*(pos_j - j) + 0] + src_matrix[pos_i + j][4*(pos_j) + 0] + src_matrix[pos_i - j][4*(pos_j) + 0]);
								suma_blue = suma_blue*(kernel_vector[abs(j)] + excedente);
								blue_acum = blue_acum + suma_blue;

								
								suma_green = (src_matrix[pos_i][4*(pos_j - j) + 1] + src_matrix[pos_i][4*(pos_j + j) + 1] + src_matrix[pos_i + j][4*(pos_j) + 1] + src_matrix[pos_i - j][4*(pos_j) + 1]);
								suma_green = suma_green*(kernel_vector[abs(j)] + excedente);
								green_acum = green_acum + suma_green;
								
								suma_red = (src_matrix[pos_i][4*(pos_j - j) + 2] + src_matrix[pos_i][4*(pos_j + j) + 2] + src_matrix[pos_i + j][4*(pos_j) + 2] + src_matrix[pos_i - j][4*(pos_j) + 2]);
								suma_red = suma_red*(kernel_vector[abs(j)] + excedente);
								red_acum = red_acum + suma_red;
								}

							else{
								suma_blue = (src_matrix[pos_i][4*(pos_j + i) + 0] + src_matrix[pos_i][4*(pos_j - i) + 0] + src_matrix[pos_i + i][4*(pos_j) + 0] + src_matrix[pos_i - i][4*(pos_j) + 0]);
								suma_blue = suma_blue*(kernel_vector[abs(j)] + excedente);
								blue_acum = blue_acum + suma_blue;

								
								suma_green = (src_matrix[pos_i][4*(pos_j - i) + 1] + src_matrix[pos_i][4*(pos_j + i) + 1] + src_matrix[pos_i + i][4*(pos_j) + 1] + src_matrix[pos_i - i][4*(pos_j) + 1]);
								suma_green = suma_green*(kernel_vector[abs(j)] + excedente);
								green_acum = green_acum + suma_green;
								
								suma_red = (src_matrix[pos_i][4*(pos_j - i) + 2] + src_matrix[pos_i][4*(pos_j + i) + 2] + src_matrix[pos_i + i][4*(pos_j) + 2] + src_matrix[pos_i - i][4*(pos_j) + 2]);
								suma_red = suma_red*(kernel_vector[abs(j)] + excedente);
								red_acum = red_acum + suma_red;								
								}					
					}
					else{
						
						int posicion;
						 
						if(abs(j) == abs(i)){
								posicion = ((2*radius - abs(j) + 3)*abs(j))/2;
						//Formula magica que averigue despues de estar un rato probando con distintos casos
						//Te da la posicion en kernel_vector donde esta alojado el elemento de la posicion i,i en la matriz kernel

								suma_blue = (src_matrix[pos_i + j][4*(pos_j + j) + 0] + src_matrix[pos_i - j][4*(pos_j - j) + 0] + src_matrix[pos_i + j][4*(pos_j - j) + 0] + src_matrix[pos_i - j][4*(pos_j + j) + 0]);
								suma_blue = suma_blue*(kernel_vector[posicion] + excedente);
								blue_acum = blue_acum + suma_blue;
															

								suma_green = (src_matrix[pos_i + j][4*(pos_j + j) + 1] + src_matrix[pos_i - j][4*(pos_j - j) + 1] + src_matrix[pos_i + j][4*(pos_j - j) + 1] + src_matrix[pos_i - j][4*(pos_j + j) + 1]);
								suma_green = suma_green*(kernel_vector[posicion] + excedente);
								green_acum = green_acum + suma_green;


								suma_red = (src_matrix[pos_i + j][4*(pos_j + j) + 2] + src_matrix[pos_i - j][4*(pos_j - j) + 2] + src_matrix[pos_i + j][4*(pos_j - j) + 2] + src_matrix[pos_i - j][4*(pos_j + j) + 2]);
								suma_red = suma_red*(kernel_vector[posicion] + excedente);
								red_acum = red_acum + suma_red;
														
						}
						else {
								if( abs(i) < abs(j)){
									posicion = ((2*radius - abs(i) + 3)*abs(i))/2;
									posicion = posicion + abs(j) - abs(i);
								//Una vez que estoy en la posicion i,i de la matriz, me corro lo que me falte para llegar a la j,i (suponiendo que j es mayor a i)
									}
								else
								{
									posicion = ((2*radius - abs(j) + 3)*abs(j))/2;
									posicion = posicion + abs(i) - abs(j);
								}
							
								suma_blue = ( src_matrix[pos_i + j][4*(pos_j + i) + 0] + src_matrix[pos_i - j][4*(pos_j - i) + 0] + src_matrix[pos_i + j][4*(pos_j - i) + 0] + src_matrix[pos_i + i][4*(pos_j + j) + 0]);
								suma_blue = suma_blue + (src_matrix[pos_i - j][4*(pos_j + i) + 0] + src_matrix[pos_i - i][4*(pos_j - j) + 0] + src_matrix[pos_i + i][4*(pos_j - j) + 0] + src_matrix[pos_i - i][4*(pos_j + j) + 0]);
								suma_blue = suma_blue*(kernel_vector[posicion] + excedente);
								blue_acum = blue_acum + suma_blue;
								
								suma_green = ( src_matrix[pos_i + j][4*(pos_j + i) + 1] + src_matrix[pos_i - j][4*(pos_j - i) + 1] + src_matrix[pos_i + j][4*(pos_j - i) + 1] + src_matrix[pos_i + i][4*(pos_j + j) + 1]);
								suma_green = suma_green + (src_matrix[pos_i - j][4*(pos_j + i) + 1] + src_matrix[pos_i - i][4*(pos_j - j) + 1] + src_matrix[pos_i + i][4*(pos_j - j) + 1] + src_matrix[pos_i - i][4*(pos_j + j) + 1]);
								suma_green = suma_green*(kernel_vector[posicion] + excedente);
								green_acum = green_acum + suma_green;

								suma_red = ( src_matrix[pos_i + j][4*(pos_j + i) + 2] + src_matrix[pos_i - j][4*(pos_j - i) + 2] + src_matrix[pos_i + j][4*(pos_j - i) + 2] + src_matrix[pos_i + i][4*(pos_j + j) + 2]);
								suma_red = suma_red + (src_matrix[pos_i - j][4*(pos_j + i) + 2] + src_matrix[pos_i - i][4*(pos_j - j) + 2] + src_matrix[pos_i + i][4*(pos_j - j) + 2] + src_matrix[pos_i - i][4*(pos_j + j) + 2]);
								suma_red = suma_red*(kernel_vector[posicion] + excedente);
								red_acum = red_acum + suma_red;

						}
					}
				}
			}
			
			}
		
			dst_matrix[pos_i][4*pos_j + 0] = (unsigned char) blue_acum;
			dst_matrix[pos_i][4*pos_j + 1] = (unsigned char) green_acum;
			dst_matrix[pos_i][4*pos_j + 2] = (unsigned char) red_acum;
			dst_matrix[pos_i][4*pos_j + 3] = 255;
			
			
			if(pos_j == radius){
				pos_j = cols - radius - 1;
				pos_i = pos_i + 1;
				}
			else{
				pos_j = pos_j - 1;
			}	
		
	}
}
