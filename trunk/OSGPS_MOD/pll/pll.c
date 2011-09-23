/****************************************************************************
* pll.c
*
*  Created on: 30.05.2011
*      Author: Gavrilov Artyom
****************************************************************************
*  History:
*
*  30.05.11  mifi   First Version.
****************************************************************************/

#include "typedefs.h"
#include "LPC23xx.h"

#define PLL_MVALUE			11  //M=value+1
#define PLL_NVALUE			0   //N=value+1
#define CCLKDivValue		        3   //devider=value+1


void pll_set_master_clock (void)
/*
 * This function should set the PLL to work with 12 MHz reference clock.
 * CPU clock should be set to 72 MHz.
 */
{
  unsigned int MValue, NValue;

  if ( PLLSTAT & (1 << 25) ) { /* Check if PLL is used as frequency source */
    PLLCON  = 1;               /* Enable PLL, disconnected */
    PLLFEED = 0xaa;
    PLLFEED = 0x55;
  }

  PLLCON  = 0;                 /* Disable PLL, disconnected */
  PLLFEED = 0xaa;
  PLLFEED = 0x55;

  SCS |= 0x20;                 /* Enable main OSC */
  while( !(SCS & 0x40) );      /* Wait until main OSC is usable */

  CLKSRCSEL = 0x1;             /* select main OSC, 12MHz, as the PLL clock source */

  PLLCFG  = PLL_MVALUE | (PLL_NVALUE << 16);
  PLLFEED = 0xaa;
  PLLFEED = 0x55;

  PLLCON  = 1;                  /* Enable PLL, disconnected */
  PLLFEED = 0xaa;
  PLLFEED = 0x55;

  CCLKCFG = CCLKDivValue;      /* Set clock divider */
  //#if USE_USB
  //    USBCLKCFG = USBCLKDivValue;		/* usbclk = 288 MHz/6 = 48 MHz */
  //#endif

  while ( ((PLLSTAT & (1 << 26)) == 0) );	/* Check lock bit status */

  MValue = PLLSTAT & 0x00007FFF;
  NValue = (PLLSTAT & 0x00FF0000) >> 16;
  while ((MValue != PLL_MVALUE) && ( NValue != PLL_NVALUE) );

  PLLCON  = 3;                                  /* enable and connect */
  PLLFEED = 0xaa;
  PLLFEED = 0x55;
  while ( ((PLLSTAT & (1 << 25)) == 0) );	/* Check connect bit status */

  /* Set UART clock source (Art)*/
  PCLKSEL0 &= ~(1<<6);
  PCLKSEL0 &= ~(1<<7);

  {
    unsigned int i, j, k;

    for(i=0; i<1000000; i++);
    j = PCLKSEL0;
    k = j+7;
  }

  return;
}

/*** EOF ***/
