
.PHONY: all
all: imagefilter_s imagefilter_p imagefilter_c imagefilter_o

.PHONY: clean
clean:
	rm -f imagefilter_s imagefilter_p imagefilter_c imagefilter_o

imagefilter_s: imagefilter.s
	gcc -g -m32 $< -o $@

imagefilter_o: imagefilter_optimized.s
	gcc -g -m32 $< -o $@

imagefilter_p: imagefilter.pas
	fpc $< -o$@

imagefilter_c: imagefilter.c
	gcc -g $< -O3 -o $@ -std=c99
