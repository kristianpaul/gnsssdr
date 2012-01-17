MMDIR=../..
include $(MMDIR)/software/include.mak

OBJECTS=crt0.o gdbstub.o
SEGMENTS=-j .text -j .data -j .rodata

# override optimization flags
CFLAGS+=-Os

all: gdbstub.elf gdbstub.bin gdbstub.rom gdbstub.h0 gdbstub.h1 gdbstub.h2 gdbstub.h3

gdbstub.h0: gdbstub.bin
	$(MMDIR)/tools/bin2hex2 $< $@ 2048 4

gdbstub.h1: gdbstub.bin
	$(MMDIR)/tools/bin2hex2 $< $@ 2048 3

gdbstub.h2: gdbstub.bin
	$(MMDIR)/tools/bin2hex2 $< $@ 2048 2

gdbstub.h3: gdbstub.bin
	$(MMDIR)/tools/bin2hex2 $< $@ 2048 1

%.bin: %.elf
	$(MAKE) -C $(MMDIR)/tools
	$(OBJCOPY) $(SEGMENTS) -O binary $< $@
	chmod -x $@
	$(MMDIR)/tools/mkmmimg $@ write

%.rom: %.bin
	$(MAKE) -C $(MMDIR)/tools
	$(MMDIR)/tools/bin2hex $< $@ 2048

gdbstub.elf: linker.ld $(OBJECTS)
	$(LD) $(LDFLAGS) -T linker.ld -N -o $@ $(OBJECTS)
	chmod -x $@

.PHONY: clean depend

depend:
	makedepend -Y -- $(CFLAGS) -- *.c

clean:
	rm -f *.o gdbstub.elf gdbstub.bin gdbstub.rom gdbstub.h0 gdbstub.h1 gdbstub.h2 gdbstub.h3 .*~ *~ Makefile.bak
