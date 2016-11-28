
.PHONY: all
all:
#all: c asm pas

clean:
	rm -f imagefilter_s imagefilter_p imagefilter_c

.PHONY: asm
asm:
	gcc imagefilter.s -o imagefilter_s

.PHONY: pas
pas:
	fpc imagefilter.pas -o imagefilter_p

.PHONY: c
c:
	gcc imagefilter.c -o imagefilter_c
