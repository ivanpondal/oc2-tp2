#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern void diff_asm (
	unsigned char *src,
	unsigned char *src_2,
	unsigned char *dst,
	int m,
	int n,
	int src_row_size,
	int src_2_row_size,
	int dst_row_size
);

int main(int argc, char* argv[]) {
  unsigned char src1[16] = {20,0,0,13, 100,10,0,0, 0,0,0,0, 0,0,0,0};
  unsigned char src2[16] = {0,0,0,200,  50 ,90,0,0, 0,0,0,0, 0,0,0,0};
  unsigned char dst[16];

  diff_asm(src1, src2, dst, 1, 4, 16, 16, 16);

  printf("[");
  for(int i=0; i<15; i++){
  	if(i%4 == 0) printf("(");
  	printf("%u", dst[i]);
  	if((i+1)%4 == 0) printf(")");
  	else printf(", ");
  }
  printf("%u)", dst[15]);
  printf("]\n");
  return 0;
}