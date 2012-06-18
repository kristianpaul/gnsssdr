/*
TNKernel real-time kernel - examples

Copyright � 2004 Yuri Tiomkin
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
#include "../TNKernel/tn.h"
#include "LPC24xx.h"
#include "utils.h"


extern TN_DQUE queueTxUart;
extern TN_SEM SemISR;
extern unsigned short status;

#define STATUS                  0x232
#define inpw(A)    async_mem_read(0x80000000+A);


//----------------------------------------------------------------------------
//   User rouitine to processing IRQ ( for LPC24XX)
//----------------------------------------------------------------------------
void tn_cpu_irq_handler(void)
{
  register int irq_stat;
  register int rc;
  int data;

  irq_stat = VICIRQStatus;

  //----- Timebase 0.8 ms int (actually this time is set by sending desired value to FPGA) -----
  if((irq_stat & (1<<15)) > 0) {
    // Drop external signal:
    status = inpw(STATUS); // (Drops interrupt request when read)
    // Clear EINT1 source:
    EXTINT = 0x00000002;
    //semaphore setting to make interrupt processing:
    tn_sem_isignal(&SemISR);

    // code from timer interrupt processing.
    tn_tick_int_processing();

    //----- UART TX Helper ----------------------
    if((U0LSR & (1<<5))>0)
    {
      rc = tn_queue_ireceive(&queueTxUart,(void **)&data);
      if(rc == TERR_NO_ERR)
        U0THR = data;
    }
    // code from timer interrupt processing - END.

  }

  VICVectAddr = 0;
}

//----------------------------------------------------------------------------
// Processor specific routine
//
// For LPC2xxx, here we enable all int vectors that we use ( not just tick timer)
// and than enable IRQ int in ARM core
//----------------------------------------------------------------------------
void tn_cpu_int_enable()
{
   //-- VIC Channel 6 - UART0, 15 - EINT1.
   VICIntEnable = (1<<6) | (1<<15);
   tn_arm_enable_interrupts();
}
