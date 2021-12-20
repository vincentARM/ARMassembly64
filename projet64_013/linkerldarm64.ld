SECTIONS
{
  PROVIDE(__executable_start = 0x0010000);
  . = 0x00400000 + SIZEOF_HEADERS;
  .interp         : { *(.interp) }
  .note.ABI-tag   : { *(.note.ABI-tag) }
  .hash           : { *(.hash) }
  .dynsym         : { *(.dynsym) }
  .dynstr         : { *(.dynstr) }
  .version        : { *(.version) }
  .version_d      : { *(.version_d) }
  .version_r      : { *(.version_r) }
  .rel.dyn        : { *(.rel.dyn) }
  .rela.dyn       : { *(.rela.dyn) }
  .rel.plt        : { *(.rel.plt) }
  .rela.plt       : { *(.rela.plt) }
  .init           : { KEEP (*(.init)) }
  .plt            : { *(.plt) }
  .text           : { *(.text .text.*) }
  .fini           : { KEEP (*(.fini)) }
  PROVIDE(__etext = .);
  PROVIDE(_etext = .);
  PROVIDE(etext = .);
  .rodata         : { *(.rodata .rodata.*) }
   __exidx_start = .;
  .ARM.exidx   : { *(.ARM.exidx*) }
   __exidx_end = .;
  . = ALIGN (CONSTANT (MAXPAGESIZE)) - ((CONSTANT (MAXPAGESIZE) - .) & (CONSTANT (MAXPAGESIZE) - 1));
  . = DATA_SEGMENT_ALIGN (CONSTANT (MAXPAGESIZE), CONSTANT (COMMONPAGESIZE));
  .tdata             : { *(.tdata .tdata.*) }
  .tbss              : { *(.tbss .tbss.*) }
  .preinit_array     :
  {
     PROVIDE_HIDDEN (__preinit_array_start = .); 
     KEEP (*(.preinit_array))
     PROVIDE_HIDDEN (__preinit_array_end = .); 
  }
  .init_array     :
  {
     PROVIDE_HIDDEN (__init_array_start = .); 
     KEEP (*(.init_array*))
     PROVIDE_HIDDEN (__init_array_end = .); 
  }
  .fini_array     :
  {
     PROVIDE_HIDDEN (__fini_array_start = .); 
     KEEP (*(.fini_array*))
     PROVIDE_HIDDEN (__fini_array_end = .); 
  }
  .dynamic        : { *(.dynamic) }
  .got            : { *(.got.plt) *(.got) }
   . = 0x420000;
  .data           :
  {
     __data_start = . ;
    *(.data .data.*)
  }
  _edata = .;
  PROVIDE(edata = .);
  __bss_start = .;
  __bss_start__ = .;
  .bss            :
  {
   *(.bss .bss.*)
   . = ALIGN(. != 0 ? 32 / 8 : 1);
  }
  __bss_end__ = .;
  _bss_end__ = .;
 .heap (NOLOAD):
{
   TAILLETAS = DEFINED(TAILLETAS) ? TAILLETAS : 0x200000 ;
    . = ALIGN(8);
     heap_begin = .;
    . = . + TAILLETAS;
    . = ALIGN(8);
    heap_end = .;
}
  . = ALIGN(4);
  __end = .;
  _end = .;
  PROVIDE(end = .);
}