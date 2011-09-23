/*****************************************************************************
 *   ex_sdram.h:  Header file for NXP LPC23xx/24xx Family Microprocessors
 *
 *   Copyright(C) 2006, NXP Semiconductor
 *   All rights reserved.
 *
 *   History
 *   2007.01.10  ver 1.00    Prelimnary version, first Release
 *
******************************************************************************/
#ifndef __EX_SRAM_H
#define __EX_SRAM_H

/*****************************************************************************
 * Defines and typedefs
 ****************************************************************************/
#define SPARTAN_MEMORY_BASE        0x80000000
#define SPARTAN_WRITE_MEMORY_BASE (0x80000000 + 0x200)
#define SPARTAN_READ_MEMORY_BASE  (0x80000000 + 0x300)

extern void SRAMInit( void );

#endif /* end __EX_SDRAM_H */
/*****************************************************************************
**                            End Of File
******************************************************************************/
