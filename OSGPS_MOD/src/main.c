/****************************************************************************
*
****************************************************************************
*  History:
*
*  10.08.11     First version.
*  16.08.11     First working version.
****************************************************************************/
#define __MAIN_C__

//#include "typedefs.h"
#include "LPC23xx.h"

#include "pll\pll.h"
#include "uart\uart.h"
#include "mprintf\mprintf.h"
#include "ex_sram\ex_sram.h"
#include "correlator\correlator.h"
#include "interrupt\irq.h"
#include "timer\timer.h"
#include "extint\extint.h"
#include "gp2021\gp2021.h"

#define PIN_MASK     (1<<15)    // Interrupt signal from correlator come to this pin.

/***************************************************************************/
/*  main                                                                   */
/***************************************************************************/
int main (void)
{
  unsigned int PIN_STATUS;      //used to check pin_status. Thus emulating interrupt.

  //LPC2478 internal parts initialization:
  pll_set_master_clock(); 	// Set PLL-block to generate 72 MHz.
  UARTInit(0, 56000);		// Init UART-block with 56000 bits/sec transfer rate.
  SRAMInit();                   // Init memory controller. It is used for communication with FPGA.

  //Correlator interface tests:
  memory_test();                //Test async memory interface used for communication with FPGA (with correlator).
  /* Fastio - temporary emulating interrupt. */
  SCS |= 0x1;                   //enable FASTIO.

  /*interrupt tests*/
  //init_VIC();             // VIC initialiation;
  //GPIOINTInit();          // GPIO interrupt enable!

  //Correlator initialization:
  correlator_init();

  while ( 1 ) {                 //endless cycle in which we always check interrupt request from correlator.
    PIN_STATUS = FIO0PIN;       //interrupt should be used instead of polling!
    if (PIN_STATUS & PIN_MASK){
      gpsisr();
    }
  }

  return 0;
}

/*** EOF ***/
