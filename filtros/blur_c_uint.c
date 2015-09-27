#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "../tp2.h"

double g_sigma(float sigm, int x_pos, int y_pos){
	const double pi = 3.1415926535897;
	double sigm_d = sigm;
	//aplico la funcion de densidad guassiana a los parametros
	double res = (exp(-(x_pos*x_pos+y_pos*y_pos)/(2*sigm_d*sigm_d)))/(2*(pi)*sigm_d*sigm_d);
	return res;	
}

int kernel_impreciso(float sigm, int m, int radio, unsigned int (*k_impreciso)[m]){	//Editar si se cambia el tipo
	int n = 2*radio + 1;
	double kernel[n][n];

//Calculo el kernel normal	
	for(int i = 0; i < n; i++){			
		for(int j = 0; j < n; j++){
			kernel[i][j] = g_sigma(sigm, j - radio, i - radio);
		}
	}


	double max_repr = (pow(2,16))/(pow(2,8));	//Editar si se cambia el tipo	
	double suma = 0;
	
	for(int j = 0; j< n; j++){
		for(int i = 0; i< n; i++){
			suma = suma + kernel[i][j];
		}
	}	
	
//Calculo por cuanto puedo multiplicar a la matriz sin irme del rango
	int exp = 0;
	while( (suma*pow(2,exp+1)) < max_repr){
		exp++;
	};

//Guardo el arreglo nuevo
	double a;
	for(int j = 0; j< n; j++){
		for(int i = 0; i< n; i++){
				a = (kernel[i][j])*(pow(2,exp));
				k_impreciso[i][j] = (unsigned int) a;	//Editar si se cambia el tipo
				}
	}
	
	return exp;
}

//FUNCION BLUR



void blur_c    (
    unsigned char *src,
    unsigned char *dst,
    int cols,
    int filas,
    float sigma,
    int radius)
{
	

    unsigned char (*src_matrix)[cols*4] = (unsigned char (*)[cols*4]) src;
    unsigned char (*dst_matrix)[cols*4] = (unsigned char (*)[cols*4]) dst;


	
//Guardo los elementos del kernel que voy a necesitar luego	
	int n = 2*radius+1;
	unsigned int kernel[n][n]; //Editar si se cambia el tipo
	int expo = kernel_impreciso(sigma, n, radius, kernel);
//Agrando cada elemento del kernel 10^i veces

	unsigned int excedente = 0;

/*	
	unsigned int suma = 0;
	
	for(int j = 0; j< n; j++){
		for(int i = 0; i< n; i++){
			suma = suma + kernel[i][j];
		}
	}	

	excedente = (pow(10,expo) - suma)/(pow(radius*2+1,2));
*/

	
	int pos_i = radius; // arranco abajo, en la posicion radius contando de abajo hacia arriba
	int pos_j = cols - radius; // arranco a radius distancia del extremo derecho

	unsigned int blue_acum;
	unsigned int red_acum;
	unsigned int green_acum;

	for(int contador = 0; contador < (cols*filas - 2*radius*(cols + filas) + 2*radius*radius); contador++ ){
// (cols*filas - 2*radius*(cols + filas) + 2*radius*radius) es la cantidad de pixels que tengo que cambiar
// Si altero mas pixels que esos me voy a ir muy al borde de la imagen y al querer agarrar elementos a radio distancia van a haber problemas
		blue_acum = 0;
		red_acum = 0;
		green_acum = 0;
		
		for(int i = 0; i < n; i++){			
			for(int j = 0; j < n; j++){
					blue_acum = blue_acum + src_matrix[pos_i + i - radius][4*(pos_j + j - radius) + 0]*(kernel[i][j]+excedente);										
					green_acum = green_acum + src_matrix[pos_i + i - radius][4*(pos_j + j - radius) + 1]*(kernel[i][j]+excedente);
					red_acum = red_acum + src_matrix[pos_i + i - radius][4*(pos_j + j - radius) + 2]*(kernel[i][j]+excedente);
					}
		}

		blue_acum = blue_acum/(pow(2,expo));
		green_acum = green_acum/(pow(2,expo));
		red_acum = red_acum/(pow(2,expo));
			
		dst_matrix[pos_i][4*pos_j + 0] = (unsigned char) blue_acum;
		dst_matrix[pos_i][4*pos_j + 1] = (unsigned char) green_acum;
		dst_matrix[pos_i][4*pos_j + 2] = (unsigned char) red_acum;
		dst_matrix[pos_i][4*pos_j + 3] = 255;
		
			
		if(pos_j == radius){
			pos_j = cols - radius;
			pos_i = pos_i + 1;
			}
		else{
			pos_j = pos_j - 1;
		}	
		
	}
}
