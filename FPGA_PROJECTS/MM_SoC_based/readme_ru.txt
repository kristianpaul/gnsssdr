 Milkymist 1.0.0 на starterkit на S3 500E http://www.xilinx.com/products/boards-and-...R3E-SK-US-G.htm 
с добавленым разъемом под SD карту, PS2 и расширеным до 12 бит VGA.

Оригинал здесь https://github.com/milkymist/milkymist/zipball/Release_1.0

Процессор 50 Мгц, ДДР 100 Мгц.  Внутренняя шина CSR -50MHz (в ориг. 80). Шина FML - 100 МГц, разрядность 32 бит вместо
64 у оригинала.
  Из БИОС по сети грузит по TFTP загрузочный образ,либо образ грузит
с SD карты. Это все работает. На USB, TMU, FPU - место не хватает, для клавиатуры и мыши использовал PS2. 
Режима STANDBY - нет, RESCUE - нет.  

 В папке ROM - бинарники БИОС, заставка и образ всей 28F128
 В папке board/s3e_sk50_10_001/ise124 проект для ise12.4 под win
 В папке cores - оригинальные используемые ядра
 В папке board/s3e_sk50_10_001/my_cores - измененные совсем или измененные части
 
 Процессор lm32(lm32_top) подключен в проект как black box.  Можно использовать для любых мс S3E.
 В папке board/s3e_sk50_10_001/my_cores/lm32 - файлы из чего он делался(собранный в Ise работае неправильно (для S3E)).
 По сравнению с оригиналом регистры перенесены в распределенную ram, 
 убран начальный сброс регистров (на работоспособность системы это не влияет).
 
 Начальная загрузка происходит так - грузится файл boot.bin в ОЗУ с 0x40000000,
 cmdline.txt с 0x41000000 и  initrd.bin  с 0x41002000.
 и с с 0x40000000  запускается. Если это не Linux то достаточно  boot.bin,
 на остальные БИОС напишет что нет их.
 
 Загрука осущесвляется с SD карт до 2Гб, отформатированных в FAT16- проверены 512Мб, 1Гб, 2Гб.
 Драйвер оригинальный пришлось поправить, он инициализирут карту как SDHC, а работает по всем
 описаниям как SD. У меня таких не нашлось.
 
 Также грузиться можно с TFTP сервера ( загрузочные файлы такие же) - я использую под win  http://tftpd32.jounin.net
 IP адрес платы 192.168.0.42 зашит в БИОС. IP адрес TFTP сервера 192.168.0.14 зашит в БИОС.
 
 Для проверки я использовал отдельную сетевую карту соединенную с платой кабелем uplink.
-----------------------------
При удачном старте БИОС выводится такое сообщение:


VGA: DDC I2C bus initialized
VGA: mode set to 640x480
                                                                               
MILKYMIST(tm) v1.0 BIOS   http://www.milkymist.org
(c) Copyright 2007, 2008, 2009, 2010, 2011 Sebastien Bourdeauducq
                                                                               
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3 of the License.
                                                                               
I: BIOS CRC passed (88250c03)
BRD: SoC 1.0 on Milkymist One (PCB revision 2)
BRD: Mem. card : Yes
BRD: AC'97     : No
BRD: PFPU      : No
BRD: TMU       : No
BRD: Ethernet  : Yes
BRD: FML meter : No
BRD: Video in  : No
BRD: MIDI      : No
BRD: DMX       : No
BRD: IR        : No
BRD: USB       : No
BRD: Memtester : No
USB: starting host controller
USB: Mouse not connect
UKB: USB keyboard connected to console
I: Displaying splash screen...OK
I: MAC address: 11:22:33:44:55:66
I: Press Q or ESC to abort boot
I: Booting from filesystem...
E: Unable to initialize memory card driver
E: Unable to initialize filesystem
I: Booting from flash...
E: Invalid flash boot image length
I: Booting from network...
I: MAC      : 11:22:33:44:55:66
I: Local IP : 192.168.0.42
I: Remote IP: 192.168.0.14
I: Unable to download boot.bin over TFTP
E: Network boot failed
E: No boot medium found
[1mBIOS>[0m                

-----------------------------
Если что-то не так, просьба сильно не пинать
 
Если есть вопросы то  mybersh@mail.ru либо в форуме

gk2

 