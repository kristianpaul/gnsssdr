MMDIR=../..
include $(MMDIR)/software/include.mak

OBJECTS=brd.o mem.o time.o

all: libhal.a

libhal.a: $(OBJECTS)
	$(AR) clr libhal.a $(OBJECTS)
	$(RANLIB) libhal.a

.PHONY: clean depend $(MMDIR)/softusb-input/softusb-input.bin

clean:
	rm -f *.o libhal.a .*~ *~ Makefile.bak

# DO NOT DELETE

brd.o: ../../software/include/base/stdlib.h
brd.o: ../../software/include/base/stdio.h
brd.o: ../../software/include/base/string.h
brd.o: ../../software/include/base/version.h
brd.o: ../../software/include/base/board.h ../../software/include/hw/sysctl.h
brd.o: ../../software/include/hw/common.h
brd.o: ../../software/include/hw/capabilities.h
brd.o: ../../software/include/hal/brd.h
mem.o: ../../software/include/base/stdio.h
mem.o: ../../software/include/base/stdlib.h
mem.o: ../../software/include/base/malloc.h ../../software/include/hal/mem.h
time.o: ../../software/include/base/stdio.h
time.o: ../../software/include/base/stdlib.h
time.o: ../../software/include/base/irq.h ../../software/include/base/board.h
time.o: ../../software/include/hw/sysctl.h ../../software/include/hw/common.h
time.o: ../../software/include/hw/interrupts.h
time.o: ../../software/include/hal/brd.h ../../software/include/hal/time.h

