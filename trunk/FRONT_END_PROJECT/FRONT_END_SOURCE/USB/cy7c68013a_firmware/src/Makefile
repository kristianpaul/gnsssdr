INCLUDES=-I../include/

CC=sdcc-sdcc -mmcs51 --no-xinit-opt

all: 	firmware

firmware: usrp_main.c usrp_common.c
	$(CC) $(INCLUDES) -c usrp_main.c -o usrp_main.rel
	$(CC) $(INCLUDES) -c usrp_common.c -o usrp_common.rel
	sdcc-asx8051 -plosgff vectors.a51
	sdcc-asx8051 -plosgff usb_descriptors.a51
	sdcc-asx8051 -plosgff _startup.a51
	$(CC) $(INCLUDES) --code-loc 0x0000 --code-size 0x1800 --xram-loc 0x1800 --xram-size 0x0800 -Wl '-b USBDESCSEG = 0xE000' -L ../lib libfx2.lib -o gn3s_firmware.ihx vectors.rel usrp_main.rel usrp_common.rel usb_descriptors.rel _startup.rel

clean:
	rm -f *.{asm,ihx,lnk,lst,map,mem,rel,rst,sym,adb,cdb,lib} 
