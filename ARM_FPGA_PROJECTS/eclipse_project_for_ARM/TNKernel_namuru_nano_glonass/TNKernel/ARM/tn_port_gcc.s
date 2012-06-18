/*

  TNKernel real-time kernel

  Copyright © 2004, 2010 Yuri Tiomkin
  All rights reserved.

  ver. 2.6

  Accembler: GCC ARM

  ffs_asm() - this is the ffs algorithm devised by D.Seal and posted to
              comp.sys.arm on  16 Feb 1994.

  Interrupt context switch -  this source code is derived on code
              written by WellsK


  Permission to use, copy, modify, and distribute this software in source
  and binary forms and its documentation for any purpose and without fee
  is hereby granted, provided that the above copyright notice appear
  in all copies and that both that copyright notice and this permission
  notice appear in supporting documentation.

  THIS SOFTWARE IS PROVIDED BY THE YURI TIOMKIN AND CONTRIBUTORS "AS IS" AND
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


  .text
  .code 32
  .align 4


  /* External references */

  .extern  tn_curr_run_task
  .extern  tn_next_task_to_run
  .extern  tn_cpu_irq_handler
  .extern  tn_system_state


  /* Public functions declared in this file */

  .global  tn_switch_context_exit
  .global  tn_switch_context
  .global  tn_cpu_irq_isr
  .global  tn_cpu_fiq_isr
  .global  tn_cpu_save_sr
  .global  tn_cpu_restore_sr
  .global  tn_start_exe
  .global  tn_chk_irq_disabled
  .global  tn_inside_irq

  .global  ffs_asm

  .global  tn_int_ctx_switch

  /* Constants */

  .equ  USERMODE,   0x10
  .equ  FIQMODE,    0x11
  .equ  IRQMODE,    0x12
  .equ  SVCMODE,    0x13
  .equ  ABORTMODE,  0x17
  .equ  UNDEFMODE,  0x1b
  .equ  MODEMASK,   0x1f
  .equ  NOINT,      0xc0           /* Disable both IRQ & FIR */
  .equ  TBIT,       0x20
  .equ  IRQMASK,    0x80
  .equ  FIQMASK,    0x40

/*----------------------------------------------------------------------------
* Interrups should be disabled here
*----------------------------------------------------------------------------*/
tn_start_exe:

     ldr    r1,=tn_system_state    /* Indicate that system has started */
     mov    r0,#1                  /*- 1 -> TN_SYS_STATE_RUNNING       */
     strb   r0,[r1]

tn_switch_context_exit:

     ldr    r0, =tn_curr_run_task
     ldr    r1, =tn_next_task_to_run
     ldr    r1, [r1]                   /* get stack pointer */
     ldr    sp, [r1]                   /* switch to the new stack */
     str    r1, [r0]                   /* set new current running task tcb address */

     ldmfd  sp!, {r0}
     msr    SPSR_cxsf, r0
     ldmfd  sp!, {r0-r12,lr,pc}^

/*----------------------------------------------------------------------------
*
*----------------------------------------------------------------------------*/
tn_switch_context:

     stmfd  sp!, {lr}                   /* Save return address */
     stmfd  sp!, {r0-r12,lr}            /* Save curr task registers */

     mrs    r0,  cpsr
     tst    LR,  #1                     /* from Thumb mode ?    */
     orrne  R0,  R0, #0x20              /* set the THUMB bit */
     stmfd  sp!, {r0}                   /* Save current CPSR */

     mrs    r0,  cpsr
     orr    r0,  r0,   #NOINT           /* Disable Int */
     msr    CPSR_c, r0

     ldr    r1,  =tn_curr_run_task
     ldr    r2,  [r1]
     ldr    r0,  =tn_next_task_to_run
     ldr    r0,  [r0]
     cmp    r2,  r0
     beq    tn_sw_restore

     str    sp,  [r2]            /* store sp in preempted tasks's TCB */
     ldr    sp,  [r0]            /* get new task's sp */
     str    r0,  [r1]            /* tn_curr_run_task = tn_next_task_to_run */

tn_sw_restore:

     ldmfd  sp!, {r0}
     msr    SPSR_cxsf, r0
     ldmfd  sp!, {r0-r12,lr,pc}^

/*----------------------------------------------------------------------------
*
*----------------------------------------------------------------------------*/
tn_cpu_irq_isr:

     sub    lr,  lr, #4             /* Set lr to the actual return address */
     stmfd  sp!, {r0-r12, lr}       /* save all registers*/

     ldr    r0,  =tn_cpu_irq_handler
     mov    lr,  pc
     bx     r0

     ldr    r0,  =tn_curr_run_task  /*  context switch ? */
     ldr    r1,  [r0]
     ldr    r0,  =tn_next_task_to_run
     ldr    r2,  [r0]
     cmp    r1,  r2                 /* if equal - return */
     beq    exit_irq_int
     b      tn_int_ctx_switch       /* else - goto context switch */

exit_irq_int:

     ldmfd  sp!, {r0-r12, pc}^      /* exit */

/*---------------------------------------------------------------------------*/
tn_int_ctx_switch:

  /* Our target - get all registers of interrrupted task, saved in IRQ's stack
  *  and save them in the interrupted task's stack
  */

     mrs    r0,  spsr                  /* Get interrupted task's CPRS  */
     stmfd  sp!, {r0}                  /* Save it in the IRQ stack */
     add    sp,  sp,  #4               /* Restore stack ptr after CPSR saving */
     ldmfd  sp!, {r0-r12, lr}          /* Put all saved registers from IRQ */
                                       /*   stack back to registers */
     mov    r1,  sp                    /* r1 <-  IRQ's SP */
     sub    r1,  r1,  #4
     msr    cpsr_c, #(NOINT | SVCMODE) /* Change to SVC mode; INT are disabled */

   /* Now - in SVC mode; in r1 - IRQ's SP */

     ldr    r0,  [r1], #-14*4          /* r0 <- task's lr (instead pc)+ rewind stack ptr */
     stmfd  sp!, {r0}
     stmfd  sp!, {r2-r12, lr}          /* Save registers in interrupted task's */
                                       /*    stack,except CPSR,r0,r1 */
     ldr    r0,  [r1], #2*4            /* Get interrupted task's CPSR (pos 0(-15))*/
     ldr    r2,  [r1], #-4             /* Get valid r1 to save (pos 2(-13)) */
     ldr    r1,  [r1]                  /* Get valid r0 to save (pos 1(-14)) */
     stmfd  sp!, {r0-r2}               /* Save r0, r1, and CPSR */

  /* Registers has been saved. Now - switch context */

     ldr    r0,  =tn_curr_run_task
     ldr    r0,  [r0]
     str    sp,  [r0]                  /* SP <- curr task */

     ldr    r0,  =tn_next_task_to_run
     ldr    r2,  [r0]
     ldr    r0,  =tn_curr_run_task
     str    r2,  [r0]
     ldr    sp,  [r2]

  /* Return */

     ldmfd  sp!, {r0}                  /* Get CPSR */
     msr    spsr_cxsf, r0              /* SPSR <- CPSR */
     ldmfd  sp!, {r0-r12, lr, pc}^     /* Restore all registers, CPSR also */

/*----------------------------------------------------------------------------
*    Do nothing here
*----------------------------------------------------------------------------*/
tn_cpu_fiq_isr:

     stmfd  SP!, {R0-R12,LR}
     ldmfd  SP!, {R0-R12,LR}    /* restore registers of interrupted task's stack */
     subs   PC, LR, #4          /* return from FIQ */

/*----------------------------------------------------------------------------
*
*----------------------------------------------------------------------------*/
tn_cpu_save_sr:

     mrs    r0,  CPSR                /* Disable both IRQ & FIQ interrupts */
     orr    r1,  r0, #NOINT
     msr    CPSR_c, r1

   /*-- Atmel add-on */

 /*  mrs    r1,CPSR        */        /* Check CPSR for correct contents */
 /*  and    r1,r1,#NOINT   */
 /*  cmp    r1,#NOINT      */
 /*  bne    tn_cpu_save_sr */        /* Not disabled - loop to try again */

     bx     lr

/*----------------------------------------------------------------------------
*
*----------------------------------------------------------------------------*/
tn_cpu_restore_sr:

     msr    CPSR_c,r0
     bx     lr

/*----------------------------------------------------------------------------
*
*----------------------------------------------------------------------------*/
tn_chk_irq_disabled:

     mrs    r0, cpsr
     and    r0, r0, #IRQMASK
     bx     lr

/*----------------------------------------------------------------------------
*
*----------------------------------------------------------------------------*/
tn_inside_irq:

     mrs    r0, cpsr
     and    r0, r0, #MODEMASK
     cmp    r0, #IRQMODE
     bne    tn_inside_int_1
     bx     lr

tn_inside_int_1:

     mov    r0, #0

     bx     lr

/*----------------------------------------------------------------------------
*
*----------------------------------------------------------------------------*/
ffs_asm:

  /* Standard trick to isolate bottom bit in r0 or 0 if r0 = 0 on entry */

     rsb    r1, r0, #0
     ands   r0, r0, r1

  /*
   * now r0 has at most one set bit, call this X
   * if X = 0, all further instructions are skipped
   */
     adrne  r2, .L_ffs_table
     orrne  r0, r0, r0, lsl #4       /* r0 = X * 0x11 */
     orrne  r0, r0, r0, lsl #6       /* r0 = X * 0x451 */
     rsbne  r0, r0, r0, lsl #16      /* r0 = X * 0x0450fbaf */

   /* now lookup in table indexed on top 6 bits of r0 */

     ldrneb r0, [ r2, r0, lsr #26 ]

     bx     lr

.L_ffs_table:
             /*   0   1   2   3   4   5   6   7           */
     .byte        0,  1,  2, 13,  3,  7,  0, 14  /*  0- 7 */
     .byte        4,  0,  8,  0,  0,  0,  0, 15  /*  8-15 */
     .byte       11,  5,  0,  0,  9,  0,  0, 26  /* 16-23 */
     .byte        0,  0,  0,  0,  0, 22, 28, 16  /* 24-31 */
     .byte       32, 12,  6,  0,  0,  0,  0,  0  /* 32-39 */
     .byte       10,  0,  0, 25,  0,  0, 21, 27  /* 40-47 */
     .byte       31,  0,  0,  0,  0, 24,  0, 20  /* 48-55 */
     .byte       30,  0, 23, 19, 29, 18, 17,  0  /* 56-63 */

/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/



