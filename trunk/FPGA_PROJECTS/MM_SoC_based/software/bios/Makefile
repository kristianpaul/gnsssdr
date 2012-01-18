MMDIR=../..
include $(MMDIR)/software/include.mak

OBJECTS=crt0.o isr.o main.o unlzma.o boot.o boot-helper.o
SEGMENTS=-j .text -j .data -j .rodata
LIBS=$(MMDIR)/software/libhpdmc/libhpdmc.a $(MMDIR)/software/libbase/libbase-light.a \
     $(MMDIR)/software/libhal/libhal.a     $(MMDIR)/software/libnet/libnet.a

all: bios.bin bios.mcs

bios.mcs: bios.bin
	$(MMDIR)/tools/bin2mcs --to-mcs --offset 8781824 bios.bin bios.mcs

%.bin: %.elf
	$(MAKE) -C $(MMDIR)/tools
	$(OBJCOPY) $(SEGMENTS) -O binary $< $@
	chmod -x $@
	$(MMDIR)/tools/mkmmimg $@ write

bios.elf: linker.ld $(OBJECTS) $(LIBS)

%.elf:
	$(LD) $(LDFLAGS) -T $< -N -o $@ $(OBJECTS) -L$(MMDIR)/software/libhpdmc -L$(MMDIR)/software/libbase -L$(MMDIR)/software/libhal -L$(MMDIR)/software/libnet --start-group -lhpdmc -lbase-light -lhal -lnet --end-group
	chmod -x $@

$(MMDIR)/software/libhpdmc/libhpdmc.a:
	make -C $(MMDIR)/software/libhpdmc/

$(MMDIR)/software/libbase/libbase-light.a:
	make -C $(MMDIR)/software/libbase/

$(MMDIR)/software/libhal/libhal.a:
	make -C $(MMDIR)/software/libhal/

$(MMDIR)/software/libnet/libnet.a:
	make -C $(MMDIR)/software/libnet/

.PHONY: clean depend $(LIBS)

depend:
	makedepend -Y -- $(CFLAGS) -- *.c

clean:
	rm -f *.o bios.elf bios.bin .*~ *~ Makefile.bak

# DO NOT DELETE

boot.o: ../../software/include/base/stdio.h
boot.o: ../../software/include/base/stdlib.h
boot.o: ../../software/include/base/console.h
boot.o: ../../software/include/base/uart.h
boot.o: ../../software/include/base/system.h
boot.o: ../../software/include/base/board.h ../../software/include/base/crc.h
boot.o: ../../tools/sfl.h ../../software/include/base/blockdev.h
boot.o: ../../software/include/base/fatfs.h
boot.o: ../../software/include/base/string.h
boot.o: ../../software/include/base/irq.h
boot.o: ../../software/include/net/microudp.h
boot.o: ../../software/include/net/tftp.h
boot.o: ../../software/include/hw/hpdmc.h
boot.o: ../../software/include/hw/common.h ../../software/include/hw/flash.h
boot.o: unlzma.h boot.h
isr.o: ../../software/include/hw/interrupts.h
isr.o: ../../software/include/base/irq.h ../../software/include/base/uart.h
isr.o: ../../software/include/hw/common.h
main.o: ../../software/include/base/stdio.h
main.o: ../../software/include/base/stdlib.h
main.o: ../../software/include/base/console.h
main.o: ../../software/include/base/string.h
main.o: ../../software/include/base/uart.h
main.o: ../../software/include/base/blockdev.h
main.o: ../../software/include/base/fatfs.h ../../software/include/base/crc.h
main.o: ../../software/include/base/system.h
main.o: ../../software/include/base/board.h ../../software/include/base/irq.h
main.o: ../../software/include/base/version.h
main.o: ../../software/include/net/mdio.h ../../software/include/hw/fmlbrg.h
main.o: ../../software/include/hw/sysctl.h ../../software/include/hw/common.h
main.o: ../../software/include/hw/gpio.h ../../software/include/hw/flash.h
main.o: ../../software/include/hw/minimac.h
main.o: ../../software/include/hal/brd.h
main.o: boot.h
unlzma.o: unlzma.h
