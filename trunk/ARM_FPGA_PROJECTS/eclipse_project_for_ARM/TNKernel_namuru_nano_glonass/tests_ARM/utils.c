/*
TNKernel real-time kernel - examples

Copyright � 2004,2005 Yuri Tiomkin
All rights reserved.

Permission to use, copy, modify, and distribute this software in source
and binary forms and its documentation for any purpose and without fee
is hereby granted, provided that the above copyright notice appear
in all copies and that both that copyright notice and this permission
notice appear in supporting documentation.

THIS SOFTWARE IS PROVIDED BY THE YURI TIOMKIN AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL YURI TIOMKIN OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.
*/

#include "LPC24xx.h"
#include "utils.h"
#include "../TNKernel/tn.h"

#define LED1      (1<<10)
#define LED2      (1<<11)

#define LED_DIR   IODIR0

#define LED_ON    IOCLR0
#define LED_OFF   IOSET0

#define PROG_ACCUM_INT_LOW      0x226
#define PROG_ACCUM_INT_HIGH     0x228
#define outpw(A,D) async_mem_write(0x80000000+A, D); //[Art]

//
extern TN_SEM  semTxUart;
extern TN_DQUE queueTxUart;


/*****************************************************************************
** Function name:               EXTINTInit
**
** Descriptions:                Initialize external interrupt (EINT1).
**
** parameters:                  None
**
** Returned value:              None
**
*****************************************************************************/
static void EXTINTInit(void)
{
  PINSEL4 |= (1<<22);        // set P2.11 as EINT1 and

  EXTMODE      = 0x00000000; // INT1 level trigger.
  EXTPOLAR     = 0x00000002; // INT1 is raising edge.
  EXTINT       = 0x00000002; // Drop interrupt signal.

  return;
}

/*****************************************************************************
** Function name:               SRAMInit
**
** Descriptions:                Initialize EMC.
**
** parameters:                  None
**
** Returned value:              None
**
*****************************************************************************/
static void SRAMInit(void)
{
  EMC_CTRL = 0x00000001;

  PCONP  |= 0x00000800;    // Turn On EMC PCLK.
  PINSEL6 = 0x55555555;
  PINSEL8 = 0x55555555;
  PINSEL9 |= 0x50550000;

  EMC_STA_CFG0      = 0x00000081;

  EMC_STA_WAITWEN0  = 0x0;
  EMC_STA_WAITOEN0  = 0x0;
  EMC_STA_WAITRD0   = 0x4; // Can be potentially reduced to 0x3 if needed.
  EMC_STA_WAITPAGE0 = 0x0;
  EMC_STA_WAITWR0   = 0x2; // Can be potentially reduced to 0x1 if needed.
  EMC_STA_WAITTURN0 = 0x0;

  return;
}

/*****************************************************************************
** Function name:               pll_set_master_clock
**
** Descriptions:                This function should set the PLL to work with
**                              12 MHz reference clock.
**                              CPU clock should be set to 72 MHz.
**
** parameters:                  desired mcu frequency [in Hz]
** Returned value:              none
**
*****************************************************************************/
static void pll_set_master_clock(int mcu_freq)
{
  unsigned int pll_mvalue;
  unsigned int pll_nvalue;
  unsigned int cclk_div_value;

  if (mcu_freq == 72000000){
    pll_mvalue = 11;
    pll_nvalue = 0;
    cclk_div_value = 3;
  }
  else if (mcu_freq == 60000000){
    pll_mvalue = 9;
    pll_nvalue = 0;
    cclk_div_value = 3;
  }
  else if (mcu_freq == 100000000){
    pll_mvalue = 99;
    pll_nvalue = 5;
    cclk_div_value = 3;
  }
  else if (mcu_freq == 140000000){
    pll_mvalue = 69;
    pll_nvalue = 5;
    cclk_div_value = 1;
  }
  else{
    pll_mvalue = 11;
    pll_nvalue = 0;
    cclk_div_value = 3;
  }

  SCS |= 0x20;                            // Enable main OSC.
  while( !(SCS & 0x40) );                 // Wait until main OSC is usable.

  CLKSRCSEL = 0x1;                        // select main OSC, 12MHz, as the PLL clock source.

  // Configure PLL:
  PLLCFG  = pll_mvalue | (pll_nvalue << 16);
  PLLFEED = 0xaa; PLLFEED = 0x55;

  PLLCON  = 1;                            // Enable PLL.
  PLLFEED = 0xaa; PLLFEED = 0x55;

  while(!( PLLSTAT & 0x04000000));        // Wait until the PLL locks.

  CCLKCFG = cclk_div_value;               // Set clock divider.

  PLLCON |= 0x2;                          // Connect the PLL.
  PLLFEED = 0xaa; PLLFEED = 0x55;
  while ( ((PLLSTAT & (1 << 25)) == 0) ); //

  return;
}

/*****************************************************************************
** Function name:               InitUART0
**
** Descriptions:                This function initialize UART0
**                              and sets it's baudrate.
**
** parameters:                  desired baudrate, fpclk.
** Returned value:              none
**
*****************************************************************************/
static void InitUART0(int baudrate, int fpclk)
{
  int Fdiv;

  PCLKSEL0 = (0x01 << 6);             //задать pclk для UART0.

  PINSEL0 = 0x00000050;               // RxD0 and TxD0.

  U0LCR = 0x83;                       // 8 bits, no Parity, 1 Stop bit.
  Fdiv = ( fpclk / 16 ) / baudrate ;  // baud rate.
  U0DLM = Fdiv / 256;
  U0DLL = Fdiv % 256;
  U0LCR = 0x03;                       // DLAB = 0.
  U0FCR = 0x07;                       // Enable and reset TX and RX FIFO.
}

/*****************************************************************************
** Function name:               LEDInit
**
** Descriptions:                This function initialize LEDs that are used.
**
**
** parameters:                  desired baudrate, fpclk.
** Returned value:              none
**
*****************************************************************************/
static void LEDInit(void)
{
  IODIR0 |= LED1;
  IODIR0 |= LED2;

  Led1Off();
  Led2Off();
}

/*****************************************************************************
** Function name:               FPGAaccumIntInit
**
** Descriptions:                This function initialize LEDs that are used.
**
**
** parameters:                  desired baudrate, fpclk.
** Returned value:              none
**
*****************************************************************************/
static void FPGAaccumIntInit(int FreqCode)
{
  ///volatile unsigned short *Pointer16;

  //set accum_int period:
  outpw(PROG_ACCUM_INT_LOW,   (FreqCode & 0x0000ffff));
  outpw(PROG_ACCUM_INT_HIGH, ((FreqCode & 0xffff0000)>>16));

  ///Pointer16  = (unsigned short *)(0x80000226);
  ///*Pointer16 = (unsigned short)(FreqCode & 0x0000ffff);
  ///Pointer16++;
  ///*Pointer16 = (unsigned short)((FreqCode & 0xffff0000)>>16);
}

/*****************************************************************************
** Function name:               HardwareInit
**
** Descriptions:                This function is called from main.
**                              It initializes all hardware.
**
**
** parameters:                  none
** Returned value:              none
**
*****************************************************************************/
void  HardwareInit(void)
{
  //PLL init:
  pll_set_master_clock(72000000);
  //UART0:
  InitUART0(115200, 72000000);
  //LED:
  LEDInit();
  //SRAM interface:
  SRAMInit();
  //Set FPGA accum_int period:
  FPGAaccumIntInit(63999);
  //EXTINT1:
  EXTINTInit();

  //Flash speed:
  MAMCR  = 2;
  MAMTIM = 3;
}

/*****************************************************************************
** Function name:               Led1On
**
** Descriptions:                Switch on LED1.
**
**
** parameters:                  none
** Returned value:              none
**
*****************************************************************************/
void Led1On(void)
{
  LED_ON |= LED1;
}

/*****************************************************************************
** Function name:               Led1Off
**
** Descriptions:                Switch off LED1.
**
**
** parameters:                  none
** Returned value:              none
**
*****************************************************************************/
void Led1Off(void)
{
  LED_OFF |= LED1;
}

/*****************************************************************************
** Function name:               Led2On
**
** Descriptions:                Switch on LED2.
**
**
** parameters:                  none
** Returned value:              none
**
*****************************************************************************/
void Led2On(void)
{
  LED_ON |= LED2;
}

/*****************************************************************************
** Function name:               Led2Off
**
** Descriptions:                Switch off LED2.
**
**
** parameters:                  none
** Returned value:              none
**
*****************************************************************************/
void Led2Off(void)
{
  LED_OFF |= LED2;
}

//----------------------------------------------------------------------------
void exs_send_to_uart(unsigned char * data)
{
  register  char * ptr;
  int i;

  tn_sem_acquire(&semTxUart,TN_WAIT_INFINITE);
  ptr = (char*) data;
  while(*ptr != '\0') {
    i = *ptr;
    tn_queue_send(&queueTxUart,(void *)i,TN_WAIT_INFINITE);
    ptr++;
  }
  tn_sem_signal(&semTxUart);
}

//----------------------------------------------------------------------------
void async_mem_write(unsigned int address, short data)
{
  volatile unsigned short *Pointer16;

  Pointer16  = (unsigned short *)(address);
  *Pointer16 = (unsigned short)(data);
}

//----------------------------------------------------------------------------
unsigned short async_mem_read(unsigned int address)
{
  volatile unsigned short *Pointer16;

  Pointer16 = (unsigned short *)(address);
  return (*Pointer16 & 0xffff);
}

//----------------------------------------------------------------------------



