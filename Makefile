
.PHONY: all
all: imagefilter_s imagefilter_p imagefilter_c

.PHONY: clean
clean:
	rm -f imagefilter_s imagefilter_p imagefilter_c

imagefilter_s:
	gcc -g -m32 imagefilter.s -o imagefilter_s

imagefilter_p:
	fpc imagefilter.pas -oimagefilter_p

imagefilter_c:
	gcc imagefilter.c -o imagefilter_c -std=c99
