/*
	GPS 1A Sampler for Windows. Streams GPS IF Samples to file. 
    Copyright (C) 2009  James T. Curran

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
*/
 
 
#ifndef _GN3S_FULL_ 
#define _GN3S_FULL_ 
 
#include <stdio.h> 
#include "usb.h"
#include <errno.h> 
#include <time.h>
#include <math.h>
#include "fusb.h"
#include "fusb_win32.h"

#include <io.h>
#include <fcntl.h>
#include <sys/stat.h> 

#include <windows.h>
#include <process.h>

#include <malloc.h>

typedef __int64 LongIntegerType;

#define DEBUG 4 

///////////////////////////////////////////////////////////////////////////////////////////
//	PACK - define the mode of the program. Ideally we would like to use 4 bytes per sample.
//	this is encoded as (0 1 2 3) = {1,-1,3,-3};
//  where the lsb of each byte is the earliest sample and a zero represents 1, 1 represents -1 etc
//  to do this we define the macro PACK
//
//	if we do not define PACK then we are using byte mode, whereby each byte is pre-decoded and 
//	represents a digitized level directly, it -1 means -1 etc
//  this mode is more memory intensive and may not always run real time.

///#define     PACK   //comment this out if you want to write 8 bits to file, otherwise we pack 4 samples to the byte

//The IF with the 16.367667 MHz clock is 4.123968 MHz, or  IF = 1575.42 MHz - (Clock * 96).

#define     DEFAULT_RECORD_DURATION	    1                  //deafault size to collect (seconds)
#define     MAX_RECORD_DURATION		28800//240	           //8 hours, coz more is just silly         //no reason really (well the 4G limit for now)
#define     FS                      16.000000e6            //sample rate
 
#define     DATA_ALIGNMENT          1024                  //just used in allocating the memory for the buffer, kB aligned memory reads/writes faster

//improtant note that the larger buffer sizes MUST all be integer multiples of the smaller ones
// also do not have FILE_WRITE_SIZE too large. a few hundred miliseconds is fine
#define     USB_READ_SIZE           16384 //16384             // ~1ms
#define     FILE_WRITE_SIZE         16384 * 32                //~1ms   * 32  // 32ms //keep this an integer multiple of USB_READ_SIZE
#define     FILE_BUFSIZE            16384 * 1024 * 16         //~16sec //keep this an integer multiple of USB_READ_SIZE and of USB_READ_SIZE

CRITICAL_SECTION CheckReadWriteStatus;

#define VID_STR      "0xFFFE"   //device specific VID
#define PID_STR      "0x0002"	//device specific PID
 
//constants.
#define RX_ENDPOINT 0x86 
 
#define VRT_VENDOR_IN 	0xC0 
#define VRT_VENDOR_OUT 	0x40 
 
#define RX_INTERFACE 2 
#define RX_ALTINTERFACE 0 
 
// IN commands 
#define VRQ_GET_STATUS 	0x80 
 
#define GS_RX_OVERRUN 	1   // wIndexL  // returns 1 byte 
 
// OUT commands 
#define VRQ_XFER    0x01 

// path to firmware-file for fx2lp device
//#define FILEPATH "e://\gn3s_firmware.ihx"
#define FILEPATH ".//\//firmware.ihx"

// unconfigured fx2 vid/pid values.
#define FX2LP_EMPTY_VID  0x04B4	//empty fx2lp device specific VID
#define FX2LP_EMPTY_PID  0x8613	//empty fx2lp device specific PID

typedef struct { 
  int interface; 
  int altinterface; 
  usb_dev_handle *udev; 
  fusb_ephandle *d_ephandle; 
  fusb_devhandle *d_devhandle; 
} fx2_config; 

// Global variables 
static const int  FUSB_BUFFER_SIZE = 16 * (1L << 20); // 8 MB 
static const int  FUSB_BLOCK_SIZE  = 16 * (1L << 10); // 16KB is hard limit 
static const int  FUSB_NBLOCKS     = FUSB_BUFFER_SIZE / FUSB_BLOCK_SIZE; 
static const char debug = DEBUG; 
 

// Additional functions to program fx2 device.
//struct usb_dev_handle *fx2_handle
///int usb_fx2_device_write_ram(size_t addr, const unsigned char *data, size_t nbytes)
int usb_fx2_device_write_ram(struct usb_dev_handle *fx2_handle, size_t addr, const unsigned char *data, size_t nbytes)
{
  int n_errors=0;

  const size_t chunk_size=16;
  const unsigned char *d=data;
  const unsigned char *dend=data+nbytes;

  while(d<dend) {
    size_t bs=dend-d;
    if(bs>chunk_size) bs=chunk_size;
    size_t dl_addr=addr+(d-data);
    int rv=usb_control_msg(fx2_handle,0x40,0xa0,
                           /*addr=*/dl_addr,0,
                           /*buf=*/(char*)d,/*size=*/bs,
                           /*timeout=*/1000/*msec*/);
    if(rv<0) {
      fprintf(stderr,"Writing %u bytes at 0x%x: %s\n", bs,dl_addr,usb_strerror());
      ++n_errors;
    }
    d+=bs;
  }

  return(n_errors);
}

///int usb_fx2_device_reset(bool running)
int usb_fx2_device_reset(struct usb_dev_handle *fx2_handle, bool running)
{
  // Reset is accomplished by writing a 1 to address 0xE600.
  // Start running by writing a 0 to that address.
  const size_t reset_addr=0xe600;
  unsigned char val = running ? 0 : 1;

//  if ( (fx2!=NULL) && (fx2_handle!=NULL) )
    return(usb_fx2_device_write_ram(fx2_handle, reset_addr,&val,1));
//  else
//  fprintf(stderr,"USB device not initialized or not opened \n");
}

int usb_fx2_device_program_ihex_line(struct usb_dev_handle *fx2_handle, const char *buf, const char *path,int line)
{
  const char *s=buf;
  if(*s!=':') {
    fprintf(stderr,"%s:%d: format violation (1)\n",path,line);
    return(1);
  }
  ++s;

  unsigned int nbytes=0,addr=0,type=0;
  if(sscanf(s,"%02x%04x%02x",&nbytes,&addr,&type)!=3) {
    fprintf(stderr,"%s:%d: format violation (2)\n",path,line);
    return(1);
  }
  s+=8;

  if(type==0) {
    //printf("  Writing nbytes=%d at addr=0x%04x\n",nbytes,addr);
    //assert(nbytes>=0 && nbytes<256);
    unsigned char data[nbytes];
    unsigned char cksum=nbytes+addr+(addr>>8)+type;
    for(unsigned int i=0; i<nbytes; i++) {
      unsigned int d=0;
      if(sscanf(s,"%02x",&d)!=1) {
        fprintf(stderr,"%s:%d: format violation (3)\n",path,line);
        return(1);
      }
      s+=2;
      data[i]=d;
      cksum+=d;
    }
    unsigned int file_cksum=0;
    if(sscanf(s,"%02x",&file_cksum)!=1) {
      fprintf(stderr,"%s:%d: format violation (4)\n",path,line);
      return(1);
    }
    if((cksum+file_cksum)&0xff) {
      fprintf(stderr,"%s:%d: checksum mismatch (%u/%u)\n",path,line,cksum,file_cksum);
      return(1);
    }
    if(usb_fx2_device_write_ram(fx2_handle, addr,data,nbytes)) {
      return(1);
    }
  }
  else if(type==1) {
    // EOF marker. Oh well, trust it.
    return(-1);
  }
  else {
    fprintf(stderr,"%s:%d: Unknown entry type %d\n",path,line,type);
    return(1);
  }

  return(0);
}

int usb_fx2_device_program_ihex_file(struct usb_dev_handle *fx2_handle)
{
///  if ( (fx2==NULL) || (fx2_handle==NULL) ){
///    fprintf(stderr,"USB device not initialized or not opened \n");
///    return(2);
///  }

  FILE *fp=fopen(FILEPATH,"r");
  if(!fp){
    fprintf(stderr,"Failed to open %s: %s\n",FILEPATH,strerror(errno));
    return(2);
  }

  int n_errors=0;

  const size_t buflen=1024;  // Hopefully much too long for real life...
  char buf[buflen];
  int line=1;

  for(;;++line) {
    *buf='\0';
    if(!fgets(buf,buflen,fp)) {
      if(feof(fp)) {
        break;
      }
      fprintf(stderr,"Reading %s (line %d): %s\n",FILEPATH,line,strerror(ferror(fp)));
      fclose(fp);
      fp=NULL;
      return(3);
    }

    int rv=usb_fx2_device_program_ihex_line(fx2_handle, buf,FILEPATH,line);
    if(rv<0) break;
    if(rv) {
      ++n_errors;
    }
  }

  if(fp) {
    fclose(fp);
  }

  return(n_errors ? -1 : 0);
}

// Send firmware to unconfigured fx2lp device.
int prog_usb_fx2_device()
{
	struct usb_bus *bus;
	struct usb_device *dev;
	int vid, pid;

	struct usb_device *fx2_device;
	struct usb_dev_handle *fx2_handle;

	dev = NULL;

	usb_init();
	usb_find_busses();
	usb_find_devices();

	vid = (FX2LP_EMPTY_VID);
	pid = (FX2LP_EMPTY_PID);

	for(bus = usb_busses; bus; bus = bus->next)
	{
		for(dev = bus->devices; dev; dev = dev->next)
		{
			if((dev->descriptor.idVendor == vid) &&	(dev->descriptor.idProduct == pid))
			{
				fx2_device = dev;
				fprintf(stdout,"FX2LP Device Found... awaiting firmware flash \n");
				break;
			}
		}
	}

	if(fx2_device == NULL)
	{
		fprintf(stderr,"Cannot find vid 0x%x pid 0x%x \n", vid, pid);
		return -1;
	}

	printf("Using device vendor id 0x%04x product id 0x%04x\n",
			fx2_device->descriptor.idVendor, fx2_device->descriptor.idProduct);

	fx2_handle = usb_open(fx2_device);

	fprintf(stdout,"GN3S flashing ... \n");

	usb_fx2_device_reset(fx2_handle, 0);
	usb_fx2_device_program_ihex_file(fx2_handle);
	usb_fx2_device_reset(fx2_handle, 1);

	fprintf(stdout,"GN3S flash complete! \n");

	usb_close(fx2_handle);

	return(0);
}

// Additional functions to program fx2 device. - END.

#include "CircularBuffer.h"

////////////////////////////////////////////////////////////////////////////////////////////
// this thread handles the reading of the circular buffer, packing 4 bytes to one and writing to file
void WriteBufferToFile(void *vDeviceDataBuffer){
	
	CircularBuffer *DeviceDataBuffer = (CircularBuffer*)vDeviceDataBuffer;

	//we wait for more data to write as long as LocalFinishedFillingBuffer is not set
	//once LocalFinishedFillingBuffer is set, we finish what is left to write, then quit
	bool LocalFinishedFillingBuffer       = 0;
	LongIntegerType BytesToWrite          = 0;
	LongIntegerType BytesWritten          = 0;

	while( !LocalFinishedFillingBuffer || ( DeviceDataBuffer->DataLeftInBuffer() > FILE_WRITE_SIZE-1 ) ){
		
		BytesToWrite = DeviceDataBuffer->GetAvailableOutputBlockSize();

		//update printout
		DeviceDataBuffer->UpdateBufferStatusPrintout();

		//write either FILE_WRITE_SIZE or nothing, wait untill there is at least FILE_WRITE_SIZE there
		if(BytesToWrite >= FILE_WRITE_SIZE){
			BytesToWrite = FILE_WRITE_SIZE;
		}
		else{
			BytesToWrite = 0;
		}

		//do actual writing!
		BytesWritten = 0;
		if(BytesToWrite > 0){
			BytesWritten = fwrite (DeviceDataBuffer->FileBufferPointer + DeviceDataBuffer->OutputBufferPos, sizeof(char), static_cast< unsigned int >( BytesToWrite ), DeviceDataBuffer->OutputFile);
		}

		//let buffer know how much we have written
		DeviceDataBuffer->AdvanceOutputBufferPosition(BytesWritten);

		//check if we are finished recording from usb
		LocalFinishedFillingBuffer = DeviceDataBuffer->FinishedLoadingData();
	
	}

	//update printout
	DeviceDataBuffer->UpdateBufferStatusPrintout(1);		
	
}

///////////////////

static int write_cmd (struct usb_dev_handle *udh, int request, int value,  
		      int index, unsigned char *bytes, int len) 
{ 
  // int r = write_cmd (udh, VRQ_XFER, start, 0, 0, 0); 
  int requesttype = (request & 0x80) ? VRT_VENDOR_IN : VRT_VENDOR_OUT;  
  int r = usb_control_msg (udh, requesttype, request, value, index,  
						   (char *) bytes, len, 1000); 
  if (r < 0){ 
	// we get EPIPE if the firmware stalls the endpoint. 
	if (errno != EPIPE) 
	  fprintf (stderr, "usb_control_msg failed: %s\n", usb_strerror ()); 
  } 
  return r; 
} 
 
 
bool _get_status (struct usb_dev_handle *udh, int which, bool *trouble) { 
  unsigned char status; 
  *trouble = true; 
 
  if (write_cmd (udh, VRQ_GET_STATUS, 0, which, 
				 &status, sizeof (status)) != sizeof (status)) 
	return false; 
 
  *trouble = (status != 0 ? 1 : 0); 
  return true; 
} 
 
 
bool check_rx_BufferOverrun (struct usb_dev_handle *udh, bool *BufferOverrun_p) { 
  return _get_status (udh, GS_RX_OVERRUN, BufferOverrun_p); 
} 
 
 
bool usrp_xfer (struct usb_dev_handle *udh, char VRQ_TYPE, bool start) {    
  int r = write_cmd (udh, VRQ_TYPE, start, 0, 0, 0); 
  return r == 0; 
} 
 
 
fusb_devhandle *make_devhandle (usb_dev_handle *udh) { 
  return new fusb_devhandle_win32 (udh); 
} 
 
 
struct usb_device *usb_fx2_find(char *num_str, char *vid_str,  
				char *pid_str, char info) { 

  struct usb_bus *bus; 
  struct usb_device *dev; 
  struct usb_device *fx2 = NULL; 
  char dev_number[3] = {0};
  usb_dev_handle *udev; 
 
  int ret, i;
  char string[256]; 
  char dev_str[32]; 

  usb_init();
  usb_find_busses();
  if (*num_str == 0)        // value hasn't been given a value, so store how
  {                         // many devices are attached.
    *num_str = usb_find_devices();
  } else {
    usb_find_devices();
  }
  
  for (bus = usb_busses; bus; bus = bus->next) { 
    for (dev = bus->devices; dev; dev = dev->next) { 
        for (i = 1; i <= *num_str;i++)  // scrolls through devices and checks
        {                               // - MW - 3.5.08
            if (i >= 127)   // this is for max var value in *num_str.
            {                
               printf("Over 127 USB devices attached, cannot proceed\n");
               fx2 = NULL;
               return fx2;
            }
              sprintf(dev_number,"%d",i);   // build string in this loop now
              strcpy(dev_str, "\\\\.\\libusb0-000");  //- MW - 3.5.08
              strcat(dev_str, dev_number);           
               strcat(dev_str, "--"); 
               strcat(dev_str, vid_str); 
               strcat(dev_str, "-"); 
               strcat(dev_str, pid_str);
			   printf("DevFilename: %s\n",dev->filename);		
               printf("dev_str:     %s\n",dev_str);
            if (strcmp(_strupr(dev->filename), _strupr(dev_str)) == 0) {
	          fx2 = dev;
			  printf("Found match.\n");
            }
        }
	   
      if (info) { 
 
	udev = usb_open(dev); 
	if (udev) { 
	  if (dev->descriptor.iManufacturer) { 
	    ret = usb_get_string_simple(udev, 
					dev->descriptor.iManufacturer, 
					string,  
					sizeof(string)); 
 
	    if (ret > 0) 
	      printf("- Manufacturer : %s\n", string); 
	    else 
	      printf("- Unable to fetch manufacturer string\n"); 
	  } 
 
	  if (dev->descriptor.iProduct) { 
	    ret = usb_get_string_simple(udev, 
					dev->descriptor.iProduct,  
					string,  
					sizeof(string)); 
 
	    if (ret > 0) 
	      printf("- Product : %s\n", string); 
	    else 
	      printf("- Unable to fetch product string\n"); 
	  } 
 
	  if (dev->descriptor.iSerialNumber) { 
	    ret = usb_get_string_simple(udev, 
					dev->descriptor.iSerialNumber, 
					string, 
					sizeof(string)); 
	     
	    if (ret > 0) 
	      printf("- Serial Number: %s\n", string); 

	    else 
	      printf("- Unable to fetch serial number string\n"); 
	  } 
	   
	  usb_close (udev); 
	} 
	 
	if (!dev->config) { 
	  printf(" Could not retrieve descriptors\n"); 
	  continue; 
	} 
	 
      } 
    } 
  }	 
   
  return fx2; 
} 
 
 
bool usb_fx2_configure(struct usb_device *fx2, fx2_config *fx2c) {  
   
  char status = 0; 
  int interface = RX_INTERFACE; 
  int altinterface = RX_ALTINTERFACE; 
  usb_dev_handle *udev; 
  fusb_ephandle *d_ephandle; 
  fusb_devhandle *d_devhandle; 
  unsigned char max2769_conf_word[4];
   
  udev = usb_open(fx2); 
   
  if (!udev) { 
    printf("Could not obtain a handle to GNSS Front-End device \n"); 
    return 1; 
  } 
  else { 
 
 
    if (usb_set_configuration (udev, 1) < 0) { 
      fprintf (stderr,  
	       "error in %s, \n%s \n", 
	       __FUNCTION__, 
	       usb_strerror()); 
      usb_close (udev); 
      status = -1; 
    } 
 
    if (usb_claim_interface (udev, interface) < 0) { 
      fprintf (stderr,  
	       "error in %s, \n%s \n", 
	       __FUNCTION__, 
	       usb_strerror()); 
      usb_close (udev); 
      fprintf (stderr, "\nDevice not programmed? \n");  
      usb_close (udev);  
      status = -1;  
      exit(0);  
    } 
 
    if (usb_set_altinterface (udev, altinterface) < 0) { 
      fprintf (stderr,  
	       "error in %s, \n%s \n", 
	       __FUNCTION__, 
	       usb_strerror()); 
      usb_close (udev); 
      usb_release_interface (udev, interface); 
      usb_close (udev); 
      status = -1; 
    } 

        //Enter here configuration code for max2769.
    //max2769_conf_word[0] = 0xA2; max2769_conf_word[1] = 0x91; max2769_conf_word[2] = 0x8F; max2769_conf_word[3] = 0x90;//LPF=18MHz!
    max2769_conf_word[0] = 0xA2; max2769_conf_word[1] = 0x91; max2769_conf_word[2] = 0x8F; max2769_conf_word[3] = 0x30;//BPF=4.2MHz!
    write_cmd(udev, 0x0C, 0, 0, max2769_conf_word, 4);
    max2769_conf_word[0] = 0x85; max2769_conf_word[1] = 0x50; max2769_conf_word[2] = 0x08; max2769_conf_word[3] = 0x81;//2bit
    //max2769_conf_word[0] = 0x85; max2769_conf_word[1] = 0x50; max2769_conf_word[2] = 0x00; max2769_conf_word[3] = 0x81;//1bit
    write_cmd(udev, 0x0C, 0, 0, max2769_conf_word, 4);
    max2769_conf_word[0] = 0xFE; max2769_conf_word[1] = 0xFF; max2769_conf_word[2] = 0x1D; max2769_conf_word[3] = 0xC2;
    write_cmd(udev, 0x0C, 0, 0, max2769_conf_word, 4);
    max2769_conf_word[0] = 0x9E; max2769_conf_word[1] = 0xC0; max2769_conf_word[2] = 0x00; max2769_conf_word[3] = 0x83;
    write_cmd(udev, 0x0C, 0, 0, max2769_conf_word, 4);
    max2769_conf_word[0] = 0x0C; max2769_conf_word[1] = 0x4A; max2769_conf_word[2] = 0x08; max2769_conf_word[3] = 0x04;//f_get=1573MHz.
    //max2769_conf_word[0] = 0x0C; max2769_conf_word[1] = 0x84; max2769_conf_word[2] = 0x08; max2769_conf_word[3] = 0x04;//f_get=1602MHz.
    //max2769_conf_word[0] = 0x0C; max2769_conf_word[1] = 0x82; max2769_conf_word[2] = 0x08; max2769_conf_word[3] = 0x04;//f_get=1601MHz.
    //max2769_conf_word[0] = 0x0C; max2769_conf_word[1] = 0x80; max2769_conf_word[2] = 0x08; max2769_conf_word[3] = 0x04;//f_get=1600MHz.
    //max2769_conf_word[0] = 0x0C; max2769_conf_word[1] = 0x7E; max2769_conf_word[2] = 0x08; max2769_conf_word[3] = 0x04;//f_get=1599MHz.
    //max2769_conf_word[0] = 0x0C; max2769_conf_word[1] = 0x7C; max2769_conf_word[2] = 0x08; max2769_conf_word[3] = 0x04;//f_get=1598MHz.
    //max2769_conf_word[0] = 0x0C; max2769_conf_word[1] = 0x7A; max2769_conf_word[2] = 0x08; max2769_conf_word[3] = 0x04;//f_get=1597MHz.
    write_cmd(udev, 0x0C, 0, 0, max2769_conf_word, 4);
    max2769_conf_word[0] = 0x08; max2769_conf_word[1] = 0x00; max2769_conf_word[2] = 0x07; max2769_conf_word[3] = 0x05;
    write_cmd(udev, 0x0C, 0, 0, max2769_conf_word, 4);
    max2769_conf_word[0] = 0x80; max2769_conf_word[1] = 0x00; max2769_conf_word[2] = 0x00; max2769_conf_word[3] = 0x06;
    write_cmd(udev, 0x0C, 0, 0, max2769_conf_word, 4);
    max2769_conf_word[0] = 0x10; max2769_conf_word[1] = 0x06; max2769_conf_word[2] = 0x1B; max2769_conf_word[3] = 0x27;
    write_cmd(udev, 0x0C, 0, 0, max2769_conf_word, 4);
    max2769_conf_word[0] = 0x1E; max2769_conf_word[1] = 0x0F; max2769_conf_word[2] = 0x40; max2769_conf_word[3] = 0x18;
    write_cmd(udev, 0x0C, 0, 0, max2769_conf_word, 4);
    max2769_conf_word[0] = 0x14; max2769_conf_word[1] = 0xC0; max2769_conf_word[2] = 0x40; max2769_conf_word[3] = 0x29;
    write_cmd(udev, 0x0C, 0, 0, max2769_conf_word, 4);
	//Enter here configuration code for max2769. END.
 
    d_devhandle=make_devhandle(udev); 
    d_ephandle = d_devhandle->make_ephandle (RX_ENDPOINT,  
					     true, 
					     FUSB_BLOCK_SIZE,  
					     FUSB_NBLOCKS); 
 
    if (!d_ephandle->start ()){ 
      fprintf (stderr, "usrp0_rx: failed to start end point streaming"); 
      usb_strerror (); 
      status = -1; 
    } 
 
    if (status == 0) { 
      fx2c->interface = interface; 
      fx2c->altinterface = altinterface; 
      fx2c->udev = udev; 
      fx2c->d_devhandle = d_devhandle; 
      fx2c->d_ephandle = d_ephandle; 
       
		return 0; 
	} 
	else { 
		return 1; 
    } 
  } 
} 



bool ConfigureOutputFile(CircularBuffer *DeviceDataBuffer, char *OutputFileName){
	
////////////////////////////////////////////////////////////

	// Open output file 
	DeviceDataBuffer->OutputFile = fopen(OutputFileName,"wb");
	if(DeviceDataBuffer->OutputFile == NULL){
		printf("Could not open Data file: %s\n.",OutputFileName); 
		return 0; 
	}
	return 1;

}


//////////////////////////////////////////////////////////////////////////////
// opens and configures the USB looking for the appropriate VID_STR and PID_STR
bool ConfigureUSB(CircularBuffer *DeviceDataBuffer, double RecordDuration){

	////////////////////////////////////////////
	//usb handles and flags
	char num_str = 0;
	char vid_str[] = VID_STR;
	char pid_str[] = PID_STR;
	DeviceDataBuffer->fx2 = 0; 


	/////////////////////////////////////////////////
	// Search all USB busses for the device specified by 
	// VID_STR and PID_STR   
	DeviceDataBuffer->fx2 = usb_fx2_find(&num_str, vid_str, pid_str, debug);

	// Open and configure FX2 device if found... 
	if (! DeviceDataBuffer->fx2) { 
		// gnsssdr additions.
		prog_usb_fx2_device();
		Sleep(1000);
		DeviceDataBuffer->fx2 = usb_fx2_find(&num_str, vid_str, pid_str, debug);
		if (! DeviceDataBuffer->fx2) {
			printf("Could not flash empty FX2LP device!\n.");
			return 0;
		}
		// gnsssdr additions. - END.
	} 
 
	DeviceDataBuffer->fx2Return = usb_fx2_configure( DeviceDataBuffer->fx2, &(DeviceDataBuffer->fx2c)); 

	if (DeviceDataBuffer->fx2Return) { 
		printf("Could not obtain a handle to the device \n"); 
		return 0; 
	}

	////////////////////////////////////////////////////////////

	/////////////////////////////////////////////////
	DeviceDataBuffer->FileBufferPointer = NULL;
	DeviceDataBuffer->FileBufferPointer = (char*)__mingw_aligned_malloc((size_t)DeviceDataBuffer->CircularBufferSize,DATA_ALIGNMENT);

	if( DeviceDataBuffer->FileBufferPointer == NULL ){
		printf("Error: could not allocate enought buffer space.\nBailing.\n");
		return 0;
	}
	////////////////////////////////////////////////////////////
	//check if record duration is reasonable
	if (RecordDuration > MAX_RECORD_DURATION){
		RecordDuration = MAX_RECORD_DURATION;
		printf("Record Duration too large, saving %us of data\n",MAX_RECORD_DURATION);
	}

	DeviceDataBuffer->NumSamplesToLoad = (LongIntegerType)ceil(0.5 * RecordDuration * double(FS));

	return 1;
}

//////////////////////////////////////////////////////////////////////////////////////////////
// this thread performs the primary read from USB operation and puts the data in a buffer for processing 
// afterwards. This must be the hightes priority thread as it works from the smallest buffer (8ms)
void CollectFromUSB(void *vDeviceDataBuffer){

	CircularBuffer *DeviceDataBuffer = (CircularBuffer*)vDeviceDataBuffer;

	//set the local thread priority to be REALTIME
	DWORD dwThreadPri;
	SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_TIME_CRITICAL);
	dwThreadPri = GetThreadPriority(GetCurrentThread());
	// check this if we like
//	printf("USB read thread priority is: %d\n", dwThreadPri);


	// Start Waveform 
	///usrp_xfer (DeviceDataBuffer->fx2c.udev, VRQ_XFER, 1);

	//////////////////////////////////////////////////////
	// Main Read-From-USB loop
	// Loop until we have enough data... 

	bool LocalFileBufferOverflow = DeviceDataBuffer->CheckCircularBufferOverflow();
	LongIntegerType RemainingSamplesToLoad = DeviceDataBuffer->CheckRemaingSamplesToLoad();
	//
	while( RemainingSamplesToLoad > 0 && !LocalFileBufferOverflow ){ 
 
/*		// Check for buffer BufferOverrun
		check_rx_BufferOverrun(DeviceDataBuffer->fx2c.udev, &(DeviceDataBuffer->USBDeviceBufferOverrun)); 
		if(DeviceDataBuffer->USBDeviceBufferOverrun) { 
			printf("GPS1A Internal Buffer Overrun.\nBailing\n");
			break; 
		}  */

		// FUSB Read... 
		DeviceDataBuffer->fx2Return = DeviceDataBuffer->fx2c.d_ephandle->read (&(DeviceDataBuffer->FileBufferPointer)[ DeviceDataBuffer->InputBufferPos ], DeviceDataBuffer->USBReadSize); 

		if (DeviceDataBuffer->fx2Return != DeviceDataBuffer->USBReadSize) { 
			printf("fusb_read: ret = %d (usb_read_size: %d)\n", DeviceDataBuffer->fx2Return, DeviceDataBuffer->USBReadSize); 
			printf("%s\n", usb_strerror()); 
			break; 
		} 
#ifdef PACK
	//nothing to do if we are packing, we do that in the write mode.
#else
	    //here we perform the LUT operation to transform the data to the {1,-1,3,-3} format from the binary format retrieved from the USB
		/*for (int j=0;j<DeviceDataBuffer->USBReadSize;j++){
				DeviceDataBuffer->FileBufferPointer[ DeviceDataBuffer->InputBufferPos + j] = LUT[DeviceDataBuffer->FileBufferPointer[ DeviceDataBuffer->InputBufferPos + j] & 0x3]; // 2 bits 
		}*/
#endif
		

		//critical section (updating USB buffer data)
		DeviceDataBuffer->AdvanceInputBufferPosition( DeviceDataBuffer->USBReadSize );

		//check for Circular Buffer Overflow
		LocalFileBufferOverflow = DeviceDataBuffer->CheckCircularBufferOverflow();

		//Check how much data is left to be loaded
		RemainingSamplesToLoad = DeviceDataBuffer->CheckRemaingSamplesToLoad();
		      
	} 

	//done filling the buffer, so tell the write thread
	DeviceDataBuffer->SetFinishedLoadingData();

	// Stop waveform 
	///usrp_xfer(DeviceDataBuffer->fx2c.udev, VRQ_XFER, 0);

}

bool CloseUSB(CircularBuffer *DeviceDataBuffer){


	//////////////////////////////////////////////
	// Clean up 
	delete DeviceDataBuffer->fx2c.d_ephandle; 
	delete DeviceDataBuffer->fx2c.d_devhandle; 

	usb_release_interface( DeviceDataBuffer->fx2c.udev,  DeviceDataBuffer->fx2c.interface); 
	usb_close( DeviceDataBuffer->fx2c.udev); 

	return 1;

}

#endif 
