#!/usr/bin/python
# -*- coding: utf-8 -*-
from scipy.stats import trim_mean
import numpy as np
import matplotlib.pyplot as plt
from sys import argv

#Salvo por diff_histogram el resto de las funciones toma un 
#parámetro f con el siguiente formato:
# f es un archivo cuyas líneas son de la forma
# TIEMPOS_EN_C.txt TIEMPOS_EN_ASM.txt TAM_IMG_USADA
# Por ej:
# ../times/test1.c.txt ../times/test1.asm.txt 32
# ../times/test2.c.txt ../times/test2.asm.txt 64
# ../times/test3.c.txt ../times/test3.asm.txt 128
# ../times/test4.c.txt ../times/test4.asm.txt 256
# ../times/test5.c.txt ../times/test5.asm.txt 512

#Para usar desde consola escribir:
#python graph.py <nombre_funcion> <archivo>

def barplot_blur(f):
	tests_c = []
	tests_asm = []
	img_sizes = []

	fobj = open(f, 'r')
	for line in fobj:
		words = line.split(' ')
		tests_c.append(fileTolist(words[0]))
		tests_asm.append(fileTolist(words[1]))
		img_sizes.append(words[2].rstrip('\n'))
	fobj.close()

	cMeans = [trim_mean(x, 0.25) for x in tests_c]
	cStd = [np.std(x) for x in tests_c]

	asmMeans = [trim_mean(x, 0.25) for x in tests_asm]
	asmStd = [np.std(x) for x in tests_asm]

	N = len(img_sizes)

	ind = np.arange(N)  # the x locations for the groups
	width = 0.35       # the width of the bars

	fig, ax = plt.subplots()
	rects1 = ax.bar(ind, cMeans, width, color='r', yerr=cStd)

	rects2 = ax.bar(ind+width, asmMeans, width, color='y', yerr=asmStd)

	# add some text for labels, title and axes ticks
	ax.set_ylabel('#ticks')
	ax.set_title(u'Blur C vs Blur ASM')
	ax.set_xticks(ind+width)
	ax.set_xlabel(u'Ancho de imagen')
	ax.set_xticklabels( img_sizes )

	ax.legend( (rects1[0], rects2[0]), ('C', 'ASM'), loc=2 )

	def autolabel(rects):
	 	# attach some text labels
	 	for rect in rects:
			height = rect.get_height()
			ax.text(rect.get_x()+rect.get_width()/2., 1.05*height, '%.1f'%(round(height,2)),ha='center', va='bottom')

	# autolabel(rects1)
	# autolabel(rects2)

	plt.savefig('barplot.blur.c.vs.asm.pdf')

def barplot_diff(f):

	tests_c = []
	tests_asm = []
	img_sizes = []

	fobj = open(f, 'r')
	for line in fobj:
		words = line.split(' ')
		tests_c.append(fileTolist(words[0]))
		tests_asm.append(fileTolist(words[1]))
		img_sizes.append(words[2].rstrip('\n'))
	fobj.close()

	cMeans = [trim_mean(x, 0.25) for x in tests_c]
	cStd = [np.std(x) for x in tests_c]

	asmMeans = [trim_mean(x, 0.25) for x in tests_asm]
	asmStd = [np.std(x) for x in tests_asm]

	N = len(img_sizes)

	ind = np.arange(N)  # the x locations for the groups
	width = 0.35       # the width of the bars

	fig, ax = plt.subplots()
	rects1 = ax.bar(ind, cMeans, width, color='r', yerr=cStd)

	rects2 = ax.bar(ind+width, asmMeans, width, color='y', yerr=asmStd)

	# add some text for labels, title and axes ticks
	ax.set_ylabel('#ticks')
	ax.set_title(u'Diff C vs Diff ASM')
	ax.set_xticks(ind+width)
	ax.set_xlabel(u'Ancho de imagen')
	ax.set_xticklabels( img_sizes )

	ax.legend( (rects1[0], rects2[0]), ('C', 'ASM'), loc=2 )

	def autolabel(rects):
	  # attach some text labels
	  for rect in rects:
	      height = rect.get_height()
	      ax.text(rect.get_x()+rect.get_width()/2., 1.05*height, '%.1f'%(round(height,2)),
	              ha='center', va='bottom')

	# autolabel(rects1)
	# autolabel(rects2)

	plt.savefig('barplot.diff.c.vs.asm.pdf')


def lineplot_diff(f):
	tests_c = []
	tests_asm = []
	img_sizes = []

	fobj = open(f, 'r')
	for line in fobj:
		words = line.split(' ')
		tests_c.append(words[0])
		tests_asm.append(words[1])
		img_sizes.append(words[2].rstrip('\n'))
	fobj.close()

	buffer_c = []
	for file in tests_c:
		times_list = fileTolist(file)
		buffer_c.append(times_list)
	
	#Normalizo
	for i in xrange(len(img_sizes)):
		buffer_c[i] = map((lambda x: x/(float(img_sizes[i])**2)), buffer_c[i])

	cMeans = []
	cStd = []
	for xs in buffer_c:
		cMeans.append(trim_mean(xs, 0.25))
		cStd.append(np.std(xs))

	buffer_asm = []
	for file in tests_asm:
		times_list = fileTolist(file)
		buffer_asm.append(times_list)
	
	#Normalizo
	for i in xrange(len(img_sizes)):
		buffer_asm[i] = map((lambda x: x/(float(img_sizes[i])**2)), buffer_asm[i])

	asmMeans = []
	asmStd = []
	for xs in buffer_asm:
		asmMeans.append(trim_mean(xs, 0.25))
		asmStd.append(np.std(xs))


	fig, ax = plt.subplots()

	plt.plot(img_sizes, cMeans, 'ro')
	rects1 = ax.errorbar(img_sizes, cMeans, yerr=cStd)

	plt.plot(img_sizes, asmMeans, 'ro')
	rects2 = ax.errorbar(img_sizes, asmMeans, yerr=asmStd)

	ax.set_ylabel('#ticks/pixel')
	ax.set_title(u'Diff C vs Diff ASM')
	ax.set_xlabel(u'Ancho de imagen')
	ax.legend( (rects1[0], rects2[0]), ('C', 'ASM'), loc=1 )

	plt.savefig('diff_lineplot.pdf')


def lineplot_blur(f):
	tests_c = []
	tests_asm = []
	img_sizes = []

	fobj = open(f, 'r')
	for line in fobj:
		words = line.split(' ')
		tests_c.append(words[0])
		tests_asm.append(words[1])
		img_sizes.append(words[2].rstrip('\n'))
	fobj.close()

	buffer_c = []
	for file in tests_c:
		times_list = fileTolist(file)
		buffer_c.append(times_list)
	
	#Normalizo
	for i in xrange(len(img_sizes)):
		buffer_c[i] = map((lambda x: x/(float(img_sizes[i])**2)), buffer_c[i])

	cMeans = []
	cStd = []
	for xs in buffer_c:
		cMeans.append(trim_mean(xs, 0.25))
		cStd.append(np.std(xs))

	buffer_asm = []
	for file in tests_asm:
		times_list = fileTolist(file)
		buffer_asm.append(times_list)
	
	#Normalizo
	for i in xrange(len(img_sizes)):
		buffer_asm[i] = map((lambda x: x/(float(img_sizes[i])**2)), buffer_asm[i])

	asmMeans = []
	asmStd = []
	for xs in buffer_asm:
		asmMeans.append(trim_mean(xs, 0.25))
		asmStd.append(np.std(xs))


	fig, ax = plt.subplots()

	plt.plot(img_sizes, cMeans, 'ro')
	rects1 = ax.errorbar(img_sizes, cMeans, yerr=cStd)

	plt.plot(img_sizes, asmMeans, 'ro')
	rects2 = ax.errorbar(img_sizes, asmMeans, yerr=asmStd)

	ax.set_ylabel('#ticks/pixel')
	ax.set_title(u'Blur C vs Blur ASM')
	ax.set_xlabel(u'Ancho de imagen')
	ax.legend( (rects1[0], rects2[0]), ('C', 'ASM'), loc=2 )

	plt.savefig('blur_lineplot.pdf')


def diff_histogram(f):
	#f es un archivo que contiene una lista de largo 256 con
	#los valores de las diferencias entre dos imágenes
	N = 256

	diff_summary = fileTolist(f)

	#No quiero considerar las componentes que difieren 0 porque están muy
	#"viciadas" por los bordes y las componentes de transparencia (que 
	# siempre valen 255 porque estoy usando escala de grises)
	diff_summary.pop(0)

	ind = np.arange(1, N)  # the x locations for the groups
	width = 0.95     # the width of the bars

	fig, ax = plt.subplots()
	rects1 = ax.bar(ind, diff_summary, width, edgecolor='none')

	# add some text for labels, title and axes ticks
	ax.set_ylabel('Cantidad de componentes')
	ax.set_title(u'Resumen de diferencias')
	ax.set_xticks(np.arange(0, 255, 20))
	ax.set_xlabel(u'Valor de la diferencia')
	ax.set_xticklabels(np.arange(0, 255, 20))

	plt.savefig('diff_histogram.pdf')

def lineplot_radio(f):
	#TIEMPOS_EN_C.txt TIEMPOS_EN_ASM.txt RADIO
	tests_c = []
	tests_asm = []
	radio_sizes = []

	fobj = open(f, 'r')
	for line in fobj:
		words = line.split(' ')
		tests_c.append(words[0])
		tests_asm.append(words[1])
		radio_sizes.append(words[2].rstrip('\n'))
	fobj.close()

	buffer_c = []
	for file in tests_c:
		times_list = fileTolist(file)
		buffer_c.append(times_list)
	
	#Normalizo
	for i in xrange(len(radio_sizes)):
		buffer_c[i] = map((lambda x: x/256**2), buffer_c[i])

	cMeans = []
	cStd = []
	for xs in buffer_c:
		cMeans.append(trim_mean(xs, 0.25))
		cStd.append(np.std(xs))

	buffer_asm = []
	for file in tests_asm:
		times_list = fileTolist(file)
		buffer_asm.append(times_list)
	
	#Normalizo
	for i in xrange(len(radio_sizes)):
		buffer_asm[i] = map((lambda x: x/256**2), buffer_asm[i])

	asmMeans = []
	asmStd = []
	for xs in buffer_asm:
		asmMeans.append(trim_mean(xs, 0.25))
		asmStd.append(np.std(xs))


	fig, ax = plt.subplots()

	plt.plot(radio_sizes, cMeans, 'ro')
	rects1 = ax.errorbar(radio_sizes, cMeans, yerr=cStd)

	plt.plot(radio_sizes, asmMeans, 'ro')
	rects2 = ax.errorbar(radio_sizes, asmMeans, yerr=asmStd)

	ax.set_ylabel('#ticks/pixel')
	ax.set_title(u'Blur C vs Blur ASM en función del tamaño del radio')
	ax.set_xlabel(u'Radio')
	ax.legend( (rects1[0], rects2[0]), ('C', 'ASM'), loc=2 )

	plt.savefig('lineplot_radio.pdf')

def barplot_radio(f):
	tests_c = []
	tests_asm = []
	radio_sizes = []

	fobj = open(f, 'r')
	for line in fobj:
		words = line.split(' ')
		tests_c.append(fileTolist(words[0]))
		tests_asm.append(fileTolist(words[1]))
		radio_sizes.append(words[2].rstrip('\n'))
	fobj.close()

	cMeans = [trim_mean(x, 0.25) for x in tests_c]
	cStd = [np.std(x) for x in tests_c]

	asmMeans = [trim_mean(x, 0.25) for x in tests_asm]
	asmStd = [np.std(x) for x in tests_asm]

	N = len(radio_sizes)

	ind = np.arange(N)  # the x locations for the groups
	width = 0.35       # the width of the bars

	fig, ax = plt.subplots()
	rects1 = ax.bar(ind, cMeans, width, color='r', yerr=cStd)

	rects2 = ax.bar(ind+width, asmMeans, width, color='y', yerr=asmStd)

	# add some text for labels, title and axes ticks
	ax.set_ylabel('#ticks')
	ax.set_title(u'Blur C vs Blur ASM')
	ax.set_xticks(ind+width)
	ax.set_xlabel(u'Radio')
	ax.set_xticklabels(radio_sizes)

	ax.legend( (rects1[0], rects2[0]), ('C', 'ASM'), loc=2 )

	def autolabel(rects):
	 	# attach some text labels
	 	for rect in rects:
			height = rect.get_height()
			ax.text(rect.get_x()+rect.get_width()/2., 1.05*height, '%.1f'%(round(height,2)),ha='center', va='bottom')

	# autolabel(rects1)
	# autolabel(rects2)

	plt.savefig('barplot_radio.pdf')


def fileTolist(f):
	fobj = open(f, "r")
	lista = []
	for line in fobj:
	    lista.append(float(line))
	fobj.close()
	return(lista)

#Selecciono la opción por línea de comando pasando los argumentos respectivos
if argv[1] == "barplot_blur":
	barplot_blur(argv[2])
elif argv[1] == "barplot_diff":
	barplot_diff(argv[2])
elif argv[1] == "diff_histogram":
	diff_histogram(argv[2])
elif argv[1] == "lineplot_diff":
	lineplot_diff(argv[2])
elif argv[1] == "lineplot_blur":
	lineplot_blur(argv[2])
elif argv[1] == "lineplot_radio":
	lineplot_radio(argv[2])
elif argv[1] == "barplot_radio":
	barplot_radio(argv[2])