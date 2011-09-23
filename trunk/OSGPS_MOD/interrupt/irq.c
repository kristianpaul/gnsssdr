/*****************************************************************************
 *   irq.c: Interrupt handler C file for NXP LPC23xx/24xx Family Microprocessors
 *
 *   Copyright(C) 2006, NXP Semiconductor
 *   All rights reserved.
 *
 *   History
 *   2006.07.13  ver 1.00    Prelimnary version, first Release
 *
 ******************************************************************************/ 

/* TODO mthomas - volatiles for vect_addr, vect_cntl? */

#include "LPC23xx.h"			/* LPC23XX/24xx Peripheral Registers */
#include "typedefs.h"
#include "irq.h"

/* Initialize the interrupt controller */
/******************************************************************************
** Function name:		init_VIC
**
** Descriptions:		Initialize VIC interrupt controller.
** parameters:			None
** Returned value:		None
** 
******************************************************************************/
void init_VIC(void) 
{
  DWORD i = 0;
  DWORD *vect_addr, *vect_cntl;

  /* initialize VIC*/
  VICIntEnClr = 0xffffffff;
  VICVectAddr = 0;
  VICIntSelect = 0;

  /* set all the vector and vector control register to 0 */
  for ( i = 0; i < VIC_SIZE; i++ ) {
    vect_addr = (DWORD *)(VIC_BASE_ADDR + VECT_ADDR_INDEX + i*4);
    vect_cntl = (DWORD *)(VIC_BASE_ADDR + VECT_CNTL_INDEX + i*4);
    *vect_addr = 0x0;
    *vect_cntl = 0xF;
  }
  return;
}

/******************************************************************************
** Function name:		install_irq
**
** Descriptions:		Install interrupt handler
** parameters:			Interrupt number, interrupt handler address, 
**						interrupt priority
** Returned value:		true or false, return false if IntNum is out of range
** 
******************************************************************************/
unsigned int install_irq(unsigned int IntNumber, void *HandlerAddr, unsigned int Priority )
{
  unsigned int *vect_addr;
  unsigned int *vect_cntl;

  VICIntEnClr = 1 << IntNumber;	/* Disable Interrupt */
  if ( IntNumber >= VIC_SIZE ) {
    return ( 0 );
  }
  else {
    /* find first un-assigned VIC address for the handler */
    vect_addr = (DWORD *)(VIC_BASE_ADDR + VECT_ADDR_INDEX + IntNumber*4);
    vect_cntl = (DWORD *)(VIC_BASE_ADDR + VECT_CNTL_INDEX + IntNumber*4);
    *vect_addr = (DWORD)HandlerAddr;	/* set interrupt vector */
    *vect_cntl = Priority;
    VICIntEnable = 1 << IntNumber;	/* Enable Interrupt */
    return( 1 );
  }
}

/******************************************************************************
**                            End Of File
******************************************************************************/
