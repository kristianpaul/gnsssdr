SOURCES = delay.c fx2utils.c isr.c usb_common.c spi.c
FX2_OBJS = $(patsubst %.c,%.rel, $(SOURCES))
INCLUDES = -I../include
SDCC = sdcc-sdcc -mmcs51
LIBS = fx2.lib

all: $(LIBS)

$(LIBS): $(FX2_OBJS)
	sdcc-sdcclib libfx2.lib $?

%.rel: %.c
	$(SDCC) $(INCLUDES) -c $?

clean:
	rm -f *.{asm,ihx,lnk,lst,map,mem,rel,rst,sym,adb,cdb,lib}

