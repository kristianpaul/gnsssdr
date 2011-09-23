/*****************************************************************************
 *   ex_sram.c:  External SDRAM memory module file for NXP LPC24xx Family
 *   Microprocessors
 *
 *   Copyright(C) 2006, NXP Semiconductor
 *   All rights reserved.
 *
 *   History
 *   2007.01.13  ver 1.00    Prelimnary version, first Release
 *
******************************************************************************/
#include "LPC23xx.h"				/* LPC23xx/24xx definitions */
#include "typedefs.h"
#include "ex_sram.h"

/*****************************************************************************
** Function name:		SRAMInit
**
** Descriptions:		Initialize external...
**
** parameters:			None
**
** Returned value:		None
**
*****************************************************************************/
void SRAMInit(void)
{
  EMC_CTRL = 0x00000001;

  PCONP  |= 0x00000800;		/* Turn On EMC PCLK */
  PINSEL5 = 0x55555555;
  PINSEL6 = 0x55555555;
  PINSEL8 = 0x55555555;
  PINSEL9 = 0x50555555;

  EMC_STA_CFG0      = 0x00000081;

  EMC_STA_WAITWEN0  = 0x0;
  EMC_STA_WAITOEN0  = 0x0;
  EMC_STA_WAITRD0   = 0x3;
  EMC_STA_WAITPAGE0 = 0x0;
  EMC_STA_WAITWR0   = 0x01;
  EMC_STA_WAITTURN0 = 0x0;

  return;
}

/*********************************************************************************
**                            End Of File
*********************************************************************************/
