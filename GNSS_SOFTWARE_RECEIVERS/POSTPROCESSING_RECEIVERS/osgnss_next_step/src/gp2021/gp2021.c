#include "gp2021.h"
#include ".\..\include\globals.h"

/*******************************************************************************************/

int inpwd(unsigned short int add)
{
  return (REG_read[add]);
}

void outpwd(unsigned short int add, unsigned short int data)
{
  REG_write[add]=data;
}

/*******************************************************************************************/

void
to_gps (int add, int data)
{
  outpwd (add, data);
}

short int
from_gps (int add)
{
  return inpwd (add);
}

/*******************************************************************************************/

int
accum_status (void)
{
  return (from_gps (0x82));
}

int
ch_i_early (int ch)
{
  return (from_gps ((ch << 3) + 0x88));
}

int
ch_q_early (int ch)
{
  return (from_gps ((ch << 3) + 0x89));
}

int
ch_i_prompt (int ch)
{
  return (from_gps ((ch << 3) + 0x86));
}

int
ch_q_prompt (int ch)
{
  return (from_gps ((ch << 3) + 0x87));
}

int
ch_i_late (int ch)
{
  return (from_gps ((ch << 3) + 0x84));
}

int
ch_q_late (int ch)
{
  return (from_gps ((ch << 3) + 0x85));
}

void
ch_code_slew (int ch, int data)
{
  to_gps ((ch << 3) + 0x84, data);
}

void
ch_carrier (int ch, long freq)
{
  int freq_hi, freq_lo;
  unsigned int add;

  long freq_local;

  // for emulating lower nco resolution:
  freq_local = freq << (MAX_DIGIT_CAPACITY_OF_ANY_NCO - CARRIER_NCO_DIGIT_CAPACITY);
  freq_local = freq_local * SYSTEM_CLOCK_MULTIPLIER; // for emulating clock frequency 5 times higher.

  freq_hi = ((int) (freq_local >> 16));
  freq_lo = ((int) (freq_local & 0xffff));
  add = (ch << 3) + 3;
  to_gps (add, freq_hi);
  add++;
  to_gps (add, freq_lo);
}

void
ch_code (int ch, long freq)
{
  int freq_hi, freq_lo;
  unsigned int add;

  long freq_local;

  // for emulating lower nco resolution (29 instead of 32):
  freq_local = freq << (MAX_DIGIT_CAPACITY_OF_ANY_NCO - CODE_NCO_DIGIT_CAPACITY);
  freq_local = freq_local * SYSTEM_CLOCK_MULTIPLIER; // for emulating clock frequency 5 times higher.

  freq_hi = (int) (freq_local >> 16);
  freq_lo = (int) (freq_local & 0xffff);
  add = (ch << 3) + 5;
  to_gps (add, freq_hi);
  add++;
  to_gps (add, freq_lo);
}

void
ch_cntl (int ch, int data)
{
  to_gps (ch << 3, data);
}

void
ch_epoch_load (int ch, unsigned int data)
{
  to_gps ((ch << 3) + 7, data);
}
