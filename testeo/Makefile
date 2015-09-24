EXTRAFLAGS:= -Wall -Werror -pedantic --std=c99 -ggdb
NASMEXTRAFLAGS:=-f elf64 -g -F dwarf 
OBJS=diff_asm.o
EXE=main
INCLUDE=-include /usr/include/errno.h 

.PHONY: all clean


$(EXE): $(EXE).c $(OBJS)
	gcc $(INCLUDE) -o $@ $(EXTRAFLAGS) $< $(OBJS)

%.o: %.asm
	nasm $(NASMEXTRAFLAGS) -o $@ $<

%.o: %.c
	gcc -c $(EXTRAFLAGS) -o $@ $<
	
all: $(EXE)

clean:
	rm -f $(OBJS)
	rm -f $(EXE)
