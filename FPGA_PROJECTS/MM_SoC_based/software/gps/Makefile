MMDIR=../..

include $(MMDIR)/software/include.mak


OBJECTS=crt0.o isr.o main.o ./mprintf/mprintf.o ./gp2021/gp2021.o ./isrl/isrl.o ./correlator/correlator.o
SEGMENTS=-j .text -j .data -j .rodata

all: gps.bin 

%.bin: %.elf
	$(MAKE) -C $(MMDIR)/tools
	$(OBJCOPY) $(SEGMENTS) -O binary $< $@
	chmod -x $@
	cp gps.bin boot.bin

# make sure the linker*.ld at the first of depends
gps.elf: linker.ld $(OBJECTS)

%.elf:
	$(LD) $(LDFLAGS) -T $< -N -o $@ $(OBJECTS)  -L$(MMDIR)/software/libbase -L$(MMDIR)/software/libhal  --start-group  -lbase-light -lhal  --end-group
	chmod -x $@
	

       
.PHONY: clean depend

depend:
	makedepend -Y -- $(CFLAGS) -- *.c

clean:
	rm -f $(OBJECTS) *.o gps.elf gps.bin boot.bin  .*~ *~ Makefile.bak

# DO NOT DELETE

isr.o: ../../software/include/hw/interrupts.h
isr.o: ../../software/include/base/irq.h ../../software/include/base/uart.h
isr.o: ../../software/include/hw/common.h
main.o: ../../software/include/base/stdio.h
main.o: ../../software/include/base/stdlib.h
main.o: ../../software/include/base/console.h
main.o: ../../software/include/base/string.h
main.o: ../../software/include/base/uart.h
main.o: ../../software/include/base/system.h
main.o: ../../software/include/base/irq.h
main.o: ../../software/include/hw/sysctl.h ../../software/include/hw/common.h
main.o: ../../software/include/hw/gpio.h 
main.o: ../../software/include/hw/fmlbrg.h
