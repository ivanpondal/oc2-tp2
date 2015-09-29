import Image
from itertools import product
from random import randint, seed
from sys import argv

#argv[1] = dimension de la imagen (siempre es cuadrada)
#argv[2] = seed

size = int(argv[1])

img = Image.new('RGB', (size, size), 'white')
seed(int(argv[2]))
for x,y in product(xrange(size),xrange(size)):
	img.putpixel((x, y), (randint(0, 255), randint(0, 255), randint(0, 255)))
## change the first parameter
img.save(str(size) + 'x' + str(size) + '(' + argv[2] + ')' + '.bmp', 'BMP')
