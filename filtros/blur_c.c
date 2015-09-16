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

	int n = (2*radius+1)*(2*radius+1);
	int pos_i = radius; // arranco abajo, en la posicion radius contando de abajo hacia arriba
	int pos_j = cols - radius; // arranco a radius distancia del extremo derecho
	double gs;

	for(int contador = 0; contador < (cols*filas - 2*radius*(cols + filas) + 2*radius*radius); contador++ ){
		
		unsigned char blue_acum = 0;
		unsigned char red_acum = 0;
		unsigned char green_acum = 0;
		int pos_x = 0;
		int pos_y = 0;
		//Recorro la zona de tamaño radius^2 alrededor de la posicion actual y calculo el valor del punto
		for(int contador2 = 0; contador2 < n; contador2++){			
			gs = g_sigma(sigma, pos_x - radius, pos_y - radius);
			blue_acum = blue_acum + src_matrix[pos_i + pos_y - radius][4*(pos_j - pos_x + radius) + 0]*gs;
			green_acum = green_acum + src_matrix[pos_i + pos_y - radius][4*(pos_j - pos_x + radius) + 1]*gs;
			red_acum = red_acum + src_matrix[pos_i + pos_y - radius][4*(pos_j - pos_x + radius) + 2]*gs;
			
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
