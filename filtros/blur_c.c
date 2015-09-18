#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "../tp2.h"


double g_sigma(float sigm, int x_pos, int y_pos){
	const double pi = 3.1415926535897;
	//aplico la funcion de densidad guassiana a los parametros
	double res = (exp(-(x_pos*x_pos+y_pos*y_pos)/(2*sigm*sigm)))/(2*(pi)*sigm*sigm);
	return res;	
}

//dada una matrix de n*n tenemos que se repiten los numeros ((r+1)/2)
//0, 1, 2, 3 ... n = vecinos
//1, 3, 6, 10 = (n+2)(n+1)/2 = numeros que se repiten




void blur_c    (
    unsigned char *src,
    unsigned char *dst,
    int cols,
    int filas,
    float sigma,
    int radius)
{

	double excedente = 0;
//Esto que esta comentado es para que el kernel sume 1 pero enrealidad no es tan importante porque ya suma casi 1, asi que el error es infimo
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

	int n = (2*radius+1)*(2*radius+1);
	int pos_i = radius; // arranco abajo, en la posicion radius contando de abajo hacia arriba
	int pos_j = cols - radius; // arranco a radius distancia del extremo derecho
	double gs;

	

	for(int contador = 0; contador < (cols*filas - 2*radius*(cols + filas) + 2*radius*radius); contador++ ){
		
		double blue_acum = 0;
		double red_acum = 0;
		double green_acum = 0;
		int pos_x = 0;
		int pos_y = 0;	


		//Recorro la zona de tamaño radius^2 alrededor de la posicion actual y calculo el valor del punto
		for(int contador2 = 0; contador2 < n; contador2++){			
			gs = g_sigma(sigma, pos_x - radius, pos_y - radius);
			blue_acum = blue_acum + src_matrix[pos_i + pos_y - radius][4*(pos_j - pos_x + radius) + 0]*(gs + excedente);
			green_acum = green_acum + src_matrix[pos_i + pos_y - radius][4*(pos_j - pos_x + radius) + 1]*(gs + excedente);
			red_acum = red_acum + src_matrix[pos_i + pos_y - radius][4*(pos_j - pos_x + radius) + 2]*(gs + excedente);
			
			if(pos_x == 2*radius + 1){
				pos_x = 0;
				pos_y++;
			}	
			else{
				pos_x++;
			}				
		}
	
		dst_matrix[pos_i][4*pos_j + 0] = blue_acum;
		dst_matrix[pos_i][4*pos_j + 1] = green_acum;
		dst_matrix[pos_i][4*pos_j + 2] = red_acum;
		dst_matrix[pos_i][4*pos_j + 3] = 255;
		
		
		if(pos_j == radius){
			pos_j = cols - radius;
			pos_i = pos_i + 1;
			}
		else{	pos_j = pos_j - 1;
		}
	}
	
}
