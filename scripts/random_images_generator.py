import Image
from itertools import product
from random import randint, seed

img = Image.new('RGB', (128, 128), 'white')
seed(100)
for x,y in product(xrange(128),xrange(128)):
    img.putpixel((x, y), (randint(0, 255), randint(0, 255), randint(0, 255)))
## change the first parameter
img.save('128x128(1).bmp', 'BMP')
