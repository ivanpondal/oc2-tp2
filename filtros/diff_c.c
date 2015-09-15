
#include <stdlib.h>
#include <math.h>
#include "../tp2.h"

void diff_c (
	unsigned char *src,
	unsigned char *src_2,
	unsigned char *dst,
	int m,
	int n,
	int src_row_size,
	int src_2_row_size,
	int dst_row_size
) {
	unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
	unsigned char (*src_2_matrix)[src_2_row_size] = (unsigned char (*)[src_2_row_size]) src_2;
	unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;
	unsigned char pixel[3];
	unsigned char infinite_norm = 0;

	for(int y = 0; y < n; y++){
		for(int x = 0; x < dst_row_size; x += 4){
			// calculo el valor absoluto de la resta entre cada componente
			pixel[RED_OFFSET] = abs(src_matrix[y][x + RED_OFFSET] - src_2_matrix[y][x + RED_OFFSET]);
			pixel[GREEN_OFFSET] = abs(src_matrix[y][x + GREEN_OFFSET] - src_2_matrix[y][x + GREEN_OFFSET]);
			pixel[BLUE_OFFSET] = abs(src_matrix[y][x + BLUE_OFFSET] - src_2_matrix[y][x + BLUE_OFFSET]);

			// busco el máximo valor absoluto de las tres componentes
			if(pixel[BLUE_OFFSET] > pixel[GREEN_OFFSET]){
				infinite_norm = (pixel[BLUE_OFFSET] > pixel[RED_OFFSET]) ? pixel[BLUE_OFFSET] : pixel[RED_OFFSET];
			}
			else{
				infinite_norm = (pixel[GREEN_OFFSET] > pixel[RED_OFFSET]) ? pixel[GREEN_OFFSET] : pixel[RED_OFFSET];
			}

			dst_matrix[y][x + RED_OFFSET] = infinite_norm;
			dst_matrix[y][x + GREEN_OFFSET] = infinite_norm;
			dst_matrix[y][x + BLUE_OFFSET] = infinite_norm;
		}
	}
}
