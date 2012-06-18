# =============================================================================
#
# Make file for TNKernel examples
#
# Processor: LPC2478
#
# Example:   tst1 - tst5
#
# Compiler: gcc version 4.5.1 (Sourcery G++ Lite 2010.09-51)
#
# No dependencies support. Call 'make clean' and than 'make' to rebuild all
#
# =============================================================================

# =========  General =============

FORMAT = ihex

# =========  Pathes ==============

TOOLSROOT = c:/Progra~1/CodeSourcery/Source~1
TOOLS     = $(TOOLSROOT)/bin/arm-none-eabi-

PRJPATH  = C:/Docume~1/engineer/workspace/TNKernel_namuru_nano_glonass/GCC
PRJPATH_MSDOS  = C:\Docume~1\engineer\workspace\TNKernel_namuru_nano_glonass\GCC

DEBUG_MSDOS    = $(PRJPATH_MSDOS)\Debug
OBJ_CLR        = $(PRJPATH_MSDOS)\OBJ

DEBUG         = $(PRJPATH)/DEBUG
OBJ           = $(PRJPATH)/OBJ
TNKERNELPATH  = $(PRJPATH)/../TNKernel
TNKERNELPATHARM = $(TNKERNELPATH)/ARM
TESTFILESPATH = $(PRJPATH)/../tests_ARM



#===========  Files  ==============

#--  Project target file name (without extension).

IMAGE = namuro_nano_tnkernel_glonass_lpc2478

#--  Linker script

LDSCRIPT = $(PRJPATH)/lpc2478_gcc.ld

#-- List of objects

OBJECTS = \
  $(OBJ)/tnkernel_startup_gcc.o\
  $(OBJ)/startup_hardware_init.o\
  $(OBJ)/tn_port_gcc.o\
  $(OBJ)/tn.o\
  $(OBJ)/tn_dqueue.o\
  $(OBJ)/tn_event.o\
  $(OBJ)/tn_mem.o\
  $(OBJ)/tn_mutex.o\
  $(OBJ)/tn_port_arm.o\
  $(OBJ)/tn_sem.o\
  $(OBJ)/tn_tasks.o\
  $(OBJ)/tn_utils.o\
  $(OBJ)/tn_user.o\
  $(OBJ)/utils.o\
  $(OBJ)/tn_sprintf.o\
  $(OBJ)/namuro_nano_tnkernel.o

OBJECTS_CLR = \
  $(OBJ_CLR)\tnkernel_startup_gcc.o\
  $(OBJ_CLR)\startup_hardware_init.o\
  $(OBJ_CLR)\tn_port_gcc.o\
  $(OBJ_CLR)\tn.o\
  $(OBJ_CLR)\tn_dqueue.o\
  $(OBJ_CLR)\tn_event.o\
  $(OBJ_CLR)\tn_mem.o\
  $(OBJ_CLR)\tn_mutex.o\
  $(OBJ_CLR)\tn_port_arm.o\
  $(OBJ_CLR)\tn_sem.o\
  $(OBJ_CLR)\tn_tasks.o\
  $(OBJ_CLR)\tn_utils.o\
  $(OBJ_CLR)\tn_user.o\
  $(OBJ_CLR)\i2c.o\
  $(OBJ_CLR)\utils.o\
  $(OBJ_CLR)\tn_sprintf.o\
  $(OBJ_CLR)\namuro_nano_tnkernel.o

# ---------------------------------------------------------------------------
#  Tools, tools options(flags)
# ---------------------------------------------------------------------------

CC      = $(TOOLS)gcc
AS      = $(TOOLS)as
CPP     = $(TOOLS)g++
LD      = $(TOOLS)ld
OBJCOPY = $(TOOLS)objcopy
OBJDUMP = $(TOOLS)objdump
SIZE    = $(TOOLS)size
NM      = $(TOOLS)nm
REMOVE  = -rm -f
COPY    = copy


OPTFLAGS = -mcpu=arm7tdmi
DEBUG =

#-- Assembler flags

ADEFS =

#ASMOPTS  = $(OPTFLAGS) $(INCLUDES) -D_GNU_ASSEMBLER_ \
#           -mlittle-endian -nostdinc -x assembler-with-cpp \
#           $(ADEFS)  -Wa,-gstabs


ASMOPTS  =  --traditional-format -march=armv4t -EL

 -Wa,-adhlns=$(<:.S=.lst),-g$(DEBUG)

#-- Compiler  flags

CDEF =

   # -Wall -Wcast-align -Wcast-qual -Wimplicit \
   # -Wmissing-prototypes -Wmissing-declarations

CCOPTS  = $(OPTFLAGS) $(INCLUDES) $(CDEF) -c \
    -Wall -Wnested-externs -Wpointer-arith -Wswitch \
    -Wredundant-decls -Wreturn-type -Wshadow -Wstrict-prototypes -Wunused \
    -O0 -g -std=c99  -march=armv4t -mlittle-endian -fno-builtin -D TNKERNEL_PORT_ARM

#-- Linker    flags

LDFLAGS =  -nostartfiles -Wl,-Map=$(OBJ)/$(IMAGE).map,--cref  -lc \
           $(NEWLIBLPC) -lm -lc -lgcc -T$(LDSCRIPT)

#        -gdwarf-2


#-- Combine all necessary flags and optional flags.

ALL_CFLAGS =  -I. $(CFLAGS)
ALL_ASFLAGS = -I. $(ASFLAGS)

# ---------------------------------------------------------------------------
#  Build
# ---------------------------------------------------------------------------

all: $(PRJPATH)/$(IMAGE).elf



#--- Compiling/Assembling ---

$(OBJ)/tnkernel_startup_gcc.o: $(PRJPATH)/tnkernel_startup_gcc.s
	$(AS) $(ASMOPTS) $(PRJPATH)/tnkernel_startup_gcc.s -o $(OBJ)/tnkernel_startup_gcc.o
$(OBJ)/startup_hardware_init.o: $(PRJPATH)/startup_hardware_init.s
	$(AS) $(ASMOPTS) $(PRJPATH)/startup_hardware_init.s -o $(OBJ)/startup_hardware_init.o
$(OBJ)/tn_port_gcc.o: $(TNKERNELPATHARM)/tn_port_gcc.s
	$(AS) $(ASMOPTS) $(TNKERNELPATHARM)/tn_port_gcc.s -o $(OBJ)/tn_port_gcc.o
$(OBJ)/tn.o: $(TNKERNELPATH)/tn.c
	$(CC) $(CCOPTS) $(TNKERNELPATH)/tn.c -o $(OBJ)/tn.o
$(OBJ)/tn_dqueue.o: $(TNKERNELPATH)/tn_dqueue.c
	$(CC) $(CCOPTS) $(TNKERNELPATH)/tn_dqueue.c -o $(OBJ)/tn_dqueue.o
$(OBJ)/tn_event.o: $(TNKERNELPATH)/tn_event.c
	$(CC) $(CCOPTS) $(TNKERNELPATH)/tn_event.c -o $(OBJ)/tn_event.o
$(OBJ)/tn_mem.o: $(TNKERNELPATH)/tn_mem.c
	$(CC) $(CCOPTS) $(TNKERNELPATH)/tn_mem.c -o $(OBJ)/tn_mem.o
$(OBJ)/tn_mutex.o: $(TNKERNELPATH)/tn_mutex.c
	$(CC) $(CCOPTS) $(TNKERNELPATH)/tn_mutex.c -o $(OBJ)/tn_mutex.o
$(OBJ)/tn_port_arm.o: $(TNKERNELPATHARM)/tn_port_arm.c
	$(CC) $(CCOPTS) $(TNKERNELPATHARM)/tn_port_arm.c -o $(OBJ)/tn_port_arm.o
$(OBJ)/tn_sem.o: $(TNKERNELPATH)/tn_sem.c
	$(CC) $(CCOPTS) $(TNKERNELPATH)/tn_sem.c -o $(OBJ)/tn_sem.o
$(OBJ)/tn_tasks.o: $(TNKERNELPATH)/tn_tasks.c
	$(CC) $(CCOPTS) $(TNKERNELPATH)/tn_tasks.c -o $(OBJ)/tn_tasks.o
$(OBJ)/tn_utils.o: $(TNKERNELPATH)/tn_utils.c
	$(CC) $(CCOPTS) $(TNKERNELPATH)/tn_utils.c -o $(OBJ)/tn_utils.o
$(OBJ)/tn_user.o: $(TESTFILESPATH)/tn_user.c
	$(CC) $(CCOPTS) $(TESTFILESPATH)/tn_user.c -o $(OBJ)/tn_user.o
$(OBJ)/utils.o: $(TESTFILESPATH)/utils.c
	$(CC) $(CCOPTS) $(TESTFILESPATH)/utils.c -o $(OBJ)/utils.o
$(OBJ)/tn_sprintf.o: $(TESTFILESPATH)/tn_sprintf.c
	$(CC) $(CCOPTS) $(TESTFILESPATH)/tn_sprintf.c -o $(OBJ)/tn_sprintf.o
$(OBJ)/i2c.o: $(TESTFILESPATH)/i2c.c
	$(CC) $(CCOPTS) $(TESTFILESPATH)/i2c.c -o $(OBJ)/i2c.o
$(OBJ)/namuro_nano_tnkernel.o: $(TESTFILESPATH)/namuro_nano_tnkernel.c
	$(CC) $(CCOPTS) $(TESTFILESPATH)/namuro_nano_tnkernel.c -o $(OBJ)/namuro_nano_tnkernel.o

#-- Linking ---

$(PRJPATH)/$(IMAGE).elf: $(OBJECTS)

	$(REMOVE)  $(OBJ_CLR)\$(IMAGE).elf
	$(REMOVE)  $(OBJ_CLR)\$(IMAGE).hex
	$(REMOVE)  $(OBJ_CLR)\$(IMAGE).map

	$(CC) $(ALL_CFLAGS) $(OBJECTS) --output $(OBJ)/$(notdir $@) $(LDFLAGS)

	$(OBJCOPY) -O$(FORMAT)    $(OBJ)/$(IMAGE).elf  $(OBJ)/$(IMAGE).hex

#--- Display size of file.

	$(SIZE) -A $(OBJ_CLR)\$(IMAGE).elf


# ===========================================================================

.PHONY:   clean

clean:

	$(REMOVE) $(OBJECTS_CLR)

# ===========================================================================
# ===========================================================================
# ===========================================================================



