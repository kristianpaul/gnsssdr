setMode -bs
setMode -bs
setCable -port auto
Identify 
identifyMPM 
assignFile -p 1 -file "C:/GavAI/GPS_rcv_final/CPLD_data_packer_v2/CPLD_data_packer/data_packer.jed"
Program -p 1 -e -v 
setMode -bs
deleteDevice -position 1
setMode -ss
setMode -sm
setMode -hw140
setMode -spi
setMode -acecf
setMode -acempm
setMode -pff
setMode -bs
