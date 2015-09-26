#!/usr/bin/python
# -*- coding: utf-8 -*-
from scipy.stats import trim_mean
import numpy as np
import matplotlib.pyplot as plt
from sys import argv

def barplot_blur(f_c, f_asm):
	N = 1

	times_c = [fileTolist(f_c)]


	cMeans = [trim_mean(x, 0.25) for x in times_c]
	cStd =   [np.std(x) for x in times_c]

	ind = np.arange(N)  # the x locations for the groups
	width = 0.35       # the width of the bars

	fig, ax = plt.subplots()
	rects1 = ax.bar(ind, cMeans, width, color='r', yerr=cStd, log=False)


	times_asm = fileTolist(f_asm)


	asmMeans = [trim_mean(x, 0.25) for x in times_asm]
	asmStd =   [np.std(x) for x in times_asm]

	rects2 = ax.bar(ind+width, asmMeans, width, color='y', yerr=asmStd, log=False)

	# add some text for labels, title and axes ticks
	ax.set_ylabel('Tiempo (#ticks)')
	ax.set_title(u'Blur C vs Blur ASM')
	ax.set_xticks(ind+width)
	ax.set_xlabel(u'Tamaño de imagen')
	ax.set_xticklabels( ('10') )
	ax.set_ylim([0, 60])

	ax.legend( (rects1[0], rects2[0]), ('C', 'ASM'), loc=1 )

	def autolabel(rects):
	  # attach some text labels
	  for rect in rects:
	      height = rect.get_height()
	      ax.text(rect.get_x()+rect.get_width()/2., 1.05*height, '%.1f'%(round(height,2)),
	              ha='center', va='bottom')

	autolabel(rects1)
	autolabel(rects2)

	plt.savefig('barplot.blur.c.vs.asm.pdf')

def barplot_diff(f_c, f_asm):
	N = 1

	times_c = fileTolist(f_c)


	cMeans = [trim_mean(times_c, 0.25)]
	cStd =   [np.std(times_c)]

	ind = np.arange(N)  # the x locations for the groups
	width = 0.35       # the width of the bars

	fig, ax = plt.subplots()
	rects1 = ax.bar(ind, cMeans, width, color='r', yerr=cStd, log=False)


	times_asm = fileTolist(f_asm)


	asmMeans = [trim_mean(times_asm, 0.25)]
	asmStd =   [np.std(times_asm)]

	rects2 = ax.bar(ind+width, asmMeans, width, color='y', yerr=asmStd, log=False)

	# add some text for labels, title and axes ticks
	ax.set_ylabel('Tiempo (#ticks)')
	ax.set_title(u'Diff C vs Diff ASM')
	ax.set_xticks(ind+width)
	ax.set_xlabel(u'Tamaño de imagen')
	ax.set_xticklabels( ('10') )

	ax.legend( (rects1[0], rects2[0]), ('C', 'ASM'), loc=1 )

	def autolabel(rects):
	  # attach some text labels
	  for rect in rects:
	      height = rect.get_height()
	      ax.text(rect.get_x()+rect.get_width()/2., 1.05*height, '%.1f'%(round(height,2)),
	              ha='center', va='bottom')

	autolabel(rects1)
	autolabel(rects2)

	plt.savefig('barplot.diff.c.vs.asm.pdf')


def diff_histogram(f):
	N = 256

	diff_summary = fileTolist(f)

	ind = np.arange(N)  # the x locations for the groups
	width = 0.95     # the width of the bars

	fig, ax = plt.subplots()
	rects1 = ax.bar(ind, diff_summary, width, edgecolor='none')

	# add some text for labels, title and axes ticks
	ax.set_ylabel('Cantidad de componentes')
	ax.set_title(u'Resumen de diferencias')
	ax.set_xticks(np.arange(0, 255, 20))
	ax.set_xlabel(u'Brecha')
	ax.set_xticklabels(np.arange(0, 255, 20))

	plt.savefig('diff_histogram.pdf')


#def lineplot_diff(f_c, f_asm, tamaños):
#	times_c = [fileTolist(x) for x in f_c]
#	times_asm = [fileTolist(x) for x in f_asm]

def fileTolist(f):
	fobj = open(f, "r")
	lista = []
	for line in fobj:
	    lista.append(float(line))
	fobj.close()
	return(lista)

if argv[1] == "barplot_blur":
	barplot_blur(argv[2], argv[3])
elif argv[1] == "barplot_diff":
	barplot_diff(argv[2], argv[3])
elif argv[1] == "diff_histogram":
	diff_histogram(argv[2])
#elif argv[1] == "lineplot_diff":
#	lineplot_diff(argv[2], argv[3], argv[4])
