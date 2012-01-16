TARGETS=bin2hex bin2mcs bin2hex2 mkmmimg flterm makeraw byteswap
#CC=clang
CC=gcc

all: $(TARGETS)

%: %.c
	$(CC) -O2 -Wall -I. -s -o $@ $<

makeraw: makeraw.c
	$(CC) -O2 -Wall -s -o $@ $< -lgd

install: mkmmimg flterm
	cp mkmmimg /usr/bin
	cp flterm /usr/bin

.PHONY: clean install

clean:
	rm -f $(TARGETS) *.o
