/****************************************************************************
* correlator.c
*
*  Created on: 30.05.2011
*      Author: Gavrilov Artyom
****************************************************************************
*  History:
*
*  30.05.11    First Version.
*  13.12.11    Second Version. Converted to MM1 SoC.
****************************************************************************/

#include "./../mprintf/mprintf.h"
#include "correlator.h"
#include "./../gp2021/gp2021.h"
#include "./../isrl/isrl.h"
#include "./../include/globals.h"

#include <irq.h>

//#include "./../softfloat/softfloat-glue.h"

#define IRQ_CRLTR			(0x00020000) /* 17 */

/*****************************************************************************
** Function name:               new_rand
**
** Descriptions:                Generates random numbers. 
**                        http://www.codeproject.com/KB/recipes/SimpleRNG.aspx
**
** parameters:                  None
**
** Returned value:              unsigned long
**
*****************************************************************************/
unsigned int new_rand()
{
  static unsigned int m_w = 521288629;
  static unsigned int m_z = 362436069;

  m_z = 36969 * (m_z & 65535) + (m_z >> 16);
  m_w = 18000 * (m_w & 65535) + (m_w >> 16);
  return (m_z << 16) + m_w;
}

/*****************************************************************************
** Function name:               memory_test
**
** Descriptions:                Tests memory
**
** parameters:                  None
**
** Returned value:              int (number of error during test)
**
*****************************************************************************/
int memory_test (void)
{
  int k;
  volatile unsigned int *Pointer32;
  unsigned int csum, rcsum;
  volatile unsigned int L;
  volatile unsigned int i, j;
  unsigned int errors;

  errors = 0;
  for (k = 0; k<2000; k++){ //repeat memory test several times;
    //First, write to memory random numbers:
    //mprintf("memory_test_c#%d:\n Writing to memory...\n", k);
    Pointer32 = (unsigned int *)(CORR_WRITE_MEMORY_BASE);
    csum=0;
    for(L=0; L<7; L++)
    {
      //i = (k+1)*L;
      i = new_rand();
      ///mprintf("%d -> %d\n", L, i);
      //i &= 0xffff;
      *Pointer32 = i;
      csum += i;
      Pointer32++;
    }

    mprintf("\n\n");

    //Now, read from memory random numbers:
    //mprintf("Reading from memory...\n");
    Pointer32 = (unsigned int *)(CORR_READ_MEMORY_BASE);
    rcsum=0;
    for(i=0; i<7; i++)
    {
      //j = *Pointer32 & 0xffff;
      j = *Pointer32;
      ///mprintf("%d -> %d\n", i, j);
      rcsum += j;
      Pointer32++;
    }

    //And bow compare check sums:
    if(csum != rcsum) {
      //mprintf("Error 0x%X 0x%X\n",csum,rcsum);
      errors++;
    }
    else {
      //mprintf("CSUM'S 0x%X 0x%X\n",csum,rcsum);
      //mprintf("Test passed!!!\n\n");
    }
  }

  if (errors)
    mprintf("MEMORY TEST FAILED!!! CAN'T ACCESS CORRELATOR MEMORY!!!\n\n");
  else
    mprintf("CORRELATOR MEMORY TEST PASSED!\n\n");

  return (errors);
}

/*****************************************************************************
** Function name:               correlator_init
**
** Descriptions:                Initializes correlator
**
** parameters:                  None
**
** Returned value:              None
**
*****************************************************************************/
void correlator_init(void)
{
  // carrier frequency resolution (carrier NCO resolution):
  Carrier_DCO_Delta = SYSTEM_CLOCK_MULTIPLIER*SAMP_RATE / (1 << CARRIER_NCO_DIGIT_CAPACITY);
  // PRN clock frequency resolution (code clock NCO resolution):
  Code_DCO_Delta    = SYSTEM_CLOCK_MULTIPLIER*SAMP_RATE / (1 << CODE_NCO_DIGIT_CAPACITY);

  // Carrier and code reference frequencies for GPS signals:
  // nominal value of code clock NCO control-word. For GPS signals:
  gps_code_ref    = 2 * GPS_CODE_F  / Code_DCO_Delta;
  // nominal value of carrier NCO control-word. For GPS signals:
  gps_carrier_ref = GPS_CARRIER_IF / Carrier_DCO_Delta; 
  // Carrier and code reference frequencies for GLONASS signals:
  // nominal value of code clock NCO control-word. For GLONASS signals:
  glonass_code_ref    = GLONASS_CODE_F  / Code_DCO_Delta;
  // nominal value of carrier NCO control-word. For GLONASS signals:
  glonass_carrier_ref = GLONASS_CARRIER_IF / Carrier_DCO_Delta;

  // Acquisition Doppler bin size (NCO control-word value):
  d_freq = (int) freq_bin_width / Carrier_DCO_Delta;

//============================================================================

  //set TIC-periode:
  program_TIC(TIC_CODE);	    
  //set ACCUM_INT periode:
  program_accum_int(ACCUM_INT_CODE);

}

/*** EOF ***/
