/*-----------------------------------------------------------------------------
//
//    TNKernel startup file  for ARM processors(running from FLASH)
//
//
// Copyright © 2004,2005 Yuri Tiomkin
// All rights reserved.
//
// Permission to use, copy, modify, and distribute this software in source
// and binary forms and its documentation for any purpose and without fee
// is hereby granted, provided that the above copyright notice appear
// in all copies and that both that copyright notice and this permission
// notice appear in supporting documentation.
//
// THIS SOFTWARE IS PROVIDED BY THE YURI TIOMKIN AND CONTRIBUTORS ``AS IS'' AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL YURI TIOMKIN OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
// OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
// LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
// OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
// SUCH DAMAGE.
//-----------------------------------------------------------------------------*/


    .equ MODE_BITS,   0x1F               /* Bit mask for mode bits in CPSR */
    .equ USR_MODE,    0x10               /* User mode */
    .equ FIQ_MODE,    0x11               /* Fast Interrupt Request mode */
    .equ IRQ_MODE,    0x12               /* Interrupt Request mode */
    .equ SVC_MODE,    0x13               /* Supervisor mode */
    .equ ABT_MODE,    0x17               /* Abort mode */
    .equ UND_MODE,    0x1B               /* Undefined Instruction mode */
    .equ SYS_MODE,    0x1F               /* System mode */


    .section    .reset, "ax"
    .global  __reset
    .global  __main
    .code 32

__main:
__reset:
        ldr  pc, reset_handler_address
        ldr  pc, undef_handler_address
        ldr  pc, swi_handler_address
        ldr  pc, pabort_handler_address
        ldr  pc, dabort_handler_address
             .word  0xB8A06F58                  /* 0 - (sum of other vectors instructions) */
        ldr  pc, irq_handler_address
        ldr  pc, fiq_handler_address

reset_handler_address:   .word  reset_handler
undef_handler_address:   .word  undef_handler
swi_handler_address:     .word  swi_handler
pabort_handler_address:  .word  pabort_handler
dabort_handler_address:  .word  dabort_handler
                         .word   0x00
irq_handler_address:     .word  tn_cpu_irq_isr
fiq_handler_address:     .word  tn_cpu_fiq_isr

    .text
    .code 32
    .align 0

reset_handler:
        b  _start
undef_handler:
        b  undef_handler
swi_handler:
        b  swi_handler
pabort_handler:
        b  pabort_handler
dabort_handler:
        b  dabort_handler

 /*--- Start */

        .extern  tn_startup_hardware_init

_start:
        ldr    r0,=tn_startup_hardware_init      /* vital hardware init */
        mov    lr,pc
        bx     r0

    /*---- init stacks */

        mrs    r0,cpsr                           /* Original PSR value */

        bic    r0,r0,#MODE_BITS                  /* Clear the mode bits */
        orr    r0,r0,#IRQ_MODE                   /* Set IRQ mode bits */
        msr    cpsr_c,r0                         /* Change the mode */
        ldr    sp, stack_irq_end                 /* End of IRQ_STACK */

        bic    r0,r0,#MODE_BITS                  /* Clear the mode bits */
        orr    r0,r0,#FIQ_MODE                   /* Set FIQ mode bits */
        msr    cpsr_c,r0                         /* Change the mode   */
        ldr    sp, stack_fiq_end                 /* End of FIQ_STACK  */

        bic    r0,r0,#MODE_BITS                  /* Clear the mode bits */
        orr    r0,r0,#SVC_MODE                   /* Set Supervisor mode bits */
        msr    cpsr_c,r0                         /* Change the mode */
        ldr    sp, stack_end                     /* End of stack */

        /*-- Leave core in SVC mode ! */


 .extern     __bss_start
 .extern     __bss_end__

     /* ----- Clear BSS (zero init) */

        mov   r0,#0
        ldr   r1,=__bss_start
        ldr   r2,=__bss_end__
2:      cmp   r1,r2
        strlo r0,[r1],#4
        blo   2b


    /*---- Copy Initialized data from FLASH to RAM */

 .extern  _etext
 .extern  _data
 .extern  _edata

        ldr   r1,=_etext
        ldr   r2,=_data
        ldr   r3,=_edata
1:      cmp   r2,r3
        ldrlo r0,[r1],#4
        strlo r0,[r2],#4
        blo   1b


   /*----  */

        .extern   main


    /*  goto main() */

        mov r0, #0
        mov r1, #0
        ldr r2, =main
        mov     lr, pc
        bx      r2

        /*--- Return from main -> loop forever. */

exit_loop:

        b      exit_loop
/*--------------------------  */
  .extern   __stack_irq_bottom_end__
  .extern   __stack_fiq_bottom_end__
  .extern   __stack_bottom_end__

stack_end:      .word   __stack_irq_bottom_end__
stack_irq_end:  .word   __stack_fiq_bottom_end__
stack_fiq_end:  .word   __stack_bottom_end__

/*-----------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------*/


