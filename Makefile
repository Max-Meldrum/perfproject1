
.PHONY: all
all: c pas # asm

clean:
	rm -f imagefilter_s imagefilter_p imagefilter_c

.PHONY: asm
asm:
	gcc -g -m32 imagefilter.s -o imagefilter_s

.PHONY: pas
pas:
	fpc imagefilter.pas -oimagefilter_p

.PHONY: c
c:
	gcc imagefilter.c -o imagefilter_c -std=c99
