
/*-----  Stack(s) size / heap size are defined here  ---------*/

   heap_size      = 1024;
   stack_fiq_size = 16;
   stack_irq_size = 256;
   stack_app_size = 1024;

/*------------------------------------------------------------------------*/
             /* LPC2478 */
MEMORY
{
   FLASH (rx) : ORIGIN = 0x00000000, LENGTH = 0x7E000
   RAM (rw)   : ORIGIN = 0x40000000, LENGTH = 0x00010000
}


SECTIONS
{

   .text :
   {
     *(.reset)                  /* Startup code */
     *(.text)                  /* remaining code */
     *(.rodata)                 /* read-only data (constants) */
     *(.rodata*)
     *(.glue_7)
     *(.glue_7t)
   } > FLASH

   . = ALIGN(4);
   _etext = . ;
   PROVIDE (etext = .);

   /* .data section which is used for initialized data */
   .data : AT (_etext)
   {
     _data = .;
     *(.data)
   } > RAM

   . = ALIGN(4);
   _edata = . ;
   PROVIDE (edata = .);

   /* .bss section which is used for uninitialized data */
   .bss (NOLOAD) :
   {
     __bss_start = . ;
     __bss_start__ = . ;
     *(.bss)
     *(COMMON)
     . = ALIGN(4);
   } > RAM

   . = ALIGN(4);
   __bss_end__ = . ;
   PROVIDE (__bss_end = .);

   .heap ALIGN(__bss_end__ , 4) (NOLOAD) :
   {
     __heap_start__ = .;
     *(.heap)
   }
   __heap_end__ = __heap_start__ + heap_size;

   .stack_bottom  ALIGN(__heap_end__ , 4) (NOLOAD) :
   {
      __stack__bottom__ = .;
      *(.stack)
   }
   __stack_bottom_end__ = __stack__bottom__  + stack_fiq_size ;

   .stack_fiq_bottom  ALIGN(__stack_bottom_end__ , 4) (NOLOAD) :
   {
      __stack__fiq_bottom__ = .;
      *(.stack)
   }
   __stack_fiq_bottom_end__ = __stack__fiq_bottom__  + stack_irq_size ;

   .stack_irq_bottom  ALIGN(__stack_fiq_bottom_end__ , 4) (NOLOAD) :
   {
      __stack_irq_bottom__ = .;
      *(.stack)
   }
   __stack_irq_bottom_end__ = __stack_irq_bottom__  + stack_app_size ;

  _end = . ;
  PROVIDE (end = .);

  /* Stabs debugging sections.  */
  .stab          0 : { *(.stab) }
  .stabstr       0 : { *(.stabstr) }
  .stab.excl     0 : { *(.stab.excl) }
  .stab.exclstr  0 : { *(.stab.exclstr) }
  .stab.index    0 : { *(.stab.index) }
  .stab.indexstr 0 : { *(.stab.indexstr) }
  .comment       0 : { *(.comment) }
  /* DWARF debug sections.
     Symbols in the DWARF debugging sections are relative to the beginning
     of the section so we begin them at 0.  */
  /* DWARF 1 */
  .debug          0 : { *(.debug) }
  .line           0 : { *(.line) }
  /* GNU DWARF 1 extensions */
  .debug_srcinfo  0 : { *(.debug_srcinfo) }
  .debug_sfnames  0 : { *(.debug_sfnames) }
  /* DWARF 1.1 and DWARF 2 */
  .debug_aranges  0 : { *(.debug_aranges) }
  .debug_pubnames 0 : { *(.debug_pubnames) }
  /* DWARF 2 */
  .debug_info     0 : { *(.debug_info .gnu.linkonce.wi.*) }
  .debug_abbrev   0 : { *(.debug_abbrev) }
  .debug_line     0 : { *(.debug_line) }
  .debug_frame    0 : { *(.debug_frame) }
  .debug_str      0 : { *(.debug_str) }
  .debug_loc      0 : { *(.debug_loc) }
  .debug_macinfo  0 : { *(.debug_macinfo) }
  /* SGI/MIPS DWARF 2 extensions */
  .debug_weaknames 0 : { *(.debug_weaknames) }
  .debug_funcnames 0 : { *(.debug_funcnames) }
  .debug_typenames 0 : { *(.debug_typenames) }
  .debug_varnames  0 : { *(.debug_varnames) }
}

