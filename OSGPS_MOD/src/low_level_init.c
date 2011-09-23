/****************************************************************************
*  Copyright (c) 2009 by Michael Fischer. All rights reserved.
*
*  Redistribution and use in source and binary forms, with or without 
*  modification, are permitted provided that the following conditions 
*  are met:
*  
*  1. Redistributions of source code must retain the above copyright 
*     notice, this list of conditions and the following disclaimer.
*  2. Redistributions in binary form must reproduce the above copyright
*     notice, this list of conditions and the following disclaimer in the 
*     documentation and/or other materials provided with the distribution.
*  3. Neither the name of the author nor the names of its contributors may 
*     be used to endorse or promote products derived from this software 
*     without specific prior written permission.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
*  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
*  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
*  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
*  THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
*  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
*  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
*  OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED 
*  AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
*  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
*  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF 
*  SUCH DAMAGE.
*
****************************************************************************
*
*  History:
*
*  25.09.09  mifi   First Version, based on the example from Quantum Leaps 
*                   with some small modifications. The original can be find 
*                   here: http://www.embedded.com/design/200900043
*
*                   For information e.g. how to setup the CPU take a look
*                   in the AT91 Software Packages which can be find here:
*                   http://www.atmel.com/dyn/products/tools_card.asp?tool_id=4343
****************************************************************************/
#define __LOW_LEVEL_INIT_C__

#include <stdint.h>

extern void UndefHandler (void);
extern void SWIHandler (void);
extern void PAbortHandler (void);
extern void DAbortHandler (void);
extern void IRQHandler (void);
extern void FIQHandler (void);

/*=========================================================================*/
/*  DEFINE: All Structures and Common Constants                            */
/*=========================================================================*/
/* LDR pc, [pc, #0x18] */
#define LDR_PC_PC       0xE59FF018U 
#define MAGIC           0xDEADBEEFU

/*=========================================================================*/
/*  DEFINE: Prototypes                                                     */
/*=========================================================================*/

/*=========================================================================*/
/*  DEFINE: Definition of all local Data                                   */
/*=========================================================================*/

/*=========================================================================*/
/*  DEFINE: Definition of all local Procedures                             */
/*=========================================================================*/

/*=========================================================================*/
/*  DEFINE: All code exported                                              */
/*=========================================================================*/
/***************************************************************************/
/*  low_level_init                                                         */
/*                                                                         */
/*  This function is invoked by the startup sequence after initializing    */
/*  the C stack, but before initializing the segments in RAM.              */
/*                                                                         */
/*  low_level_init() is invoked in the ARM state. The function gives the   */
/*  application a chance to perform early initializations of the hardware. */
/*  This function cannot rely on initialization of any static variables,   */
/*  because these have not yet been initialized in RAM.                    */
/***************************************************************************/
void low_level_init (void *reset_addr, void *return_addr) 
{
   extern uint8_t __ram_start;
   
   /*******************************************************************/
   /*  Warning, warning, warning, warning, warning, warning           */
   /*                                                                 */
   /*  This trick is used to check if we are running from Flash.      */
   /*  In this case __ram_start is set to the RAM start address       */
   /*  of the LPC, which is 0x40000000.                           */
   /*                                                                 */
   /*  Only than, we can map the exception vectors from RAM to Flash. */
   /*******************************************************************/
   if ((uint32_t)&__ram_start == 0x40000000)
   {
      /* 
       * Setup the exception vectors to RAM
       *
       * NOTE: the exception vectors must be in RAM *before* the remap
       * in order to guarantee that the ARM core is provided with valid vectors
       * during the remap operation.
       */
       
      /* Setup the primary vector table in RAM */
      *(uint32_t volatile *)(&__ram_start + 0x00) = LDR_PC_PC;
      *(uint32_t volatile *)(&__ram_start + 0x04) = LDR_PC_PC;
      *(uint32_t volatile *)(&__ram_start + 0x08) = LDR_PC_PC;
      *(uint32_t volatile *)(&__ram_start + 0x0C) = LDR_PC_PC;
      *(uint32_t volatile *)(&__ram_start + 0x10) = LDR_PC_PC;
      *(uint32_t volatile *)(&__ram_start + 0x14) = MAGIC;
      *(uint32_t volatile *)(&__ram_start + 0x18) = LDR_PC_PC;
      *(uint32_t volatile *)(&__ram_start + 0x1C) = LDR_PC_PC;

      /* setup the secondary vector table in RAM */
      *(uint32_t volatile *)(&__ram_start + 0x20) = (uint32_t)reset_addr;
      *(uint32_t volatile *)(&__ram_start + 0x24) = (uint32_t)UndefHandler;
      *(uint32_t volatile *)(&__ram_start + 0x28) = (uint32_t)SWIHandler;
      *(uint32_t volatile *)(&__ram_start + 0x2C) = (uint32_t)PAbortHandler;
      *(uint32_t volatile *)(&__ram_start + 0x30) = (uint32_t)DAbortHandler;
      *(uint32_t volatile *)(&__ram_start + 0x34) = 0;
      *(uint32_t volatile *)(&__ram_start + 0x38) = (uint32_t)IRQHandler;
      *(uint32_t volatile *)(&__ram_start + 0x3C) = (uint32_t)FIQHandler;

      /* 
       * Check if the Memory Controller has been remapped already 
       */
      if (MAGIC != (*(uint32_t volatile *)0x14)) 
      {
         /* perform Memory Controller remapping */
         // Add command here
      }
   }      
   
} /* low_level_init */

/*** EOF ***/
