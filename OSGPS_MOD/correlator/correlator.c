/****************************************************************************
* pll.c
*
*  Created on: 30.05.2011
*      Author: Gavrilov Artyom
****************************************************************************
*  History:
*
*  30.05.11  mifi   First Version.
****************************************************************************/

#include ".\..\ex_sram\ex_sram.h"
#include ".\..\mprintf\mprintf.h"
#include ".\correlator.h"
#include "gp2021\gp2021.h"
#include "isr\isr.h"

/*=========================================================================*/
/*  DEFINE: Definition of all local Data                                   */
/*=========================================================================*/
#define CODE_REF    0x00D182A9  //code clock rate nominal frequency: (2.046e6*2^29)/80e6;
                                // 29 - number of bits in code_nco phase accumulator;
                                // (2.046e6 = 1.023e6*2) - doubled chip rate;
                                // 80e6 - correlator clock frequency;
#define CARRIER_REF 0x01EF9DB2  // carrier nominal frequency: (2.42e6*2^30)/80e6;
                                // 30 - number of bits in carrier_nco phase accumulator;
                                // 2.42e6 - nominal IF in rf-front-end;
                                // 80e6 - correlator clock frequency;
/*=========================================================================*/
/*  DEFINE: All code exported                                              */
/*=========================================================================*/
extern struct tracking_channel chan[1]; // array of structures that describe each correlator channel;

/*****************************************************************************
** Function name:               new_rand
**
** Descriptions:                Generates random numbers. http://www.codeproject.com/KB/recipes/SimpleRNG.aspx
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
  volatile unsigned short *Pointer16;
  unsigned int csum, rcsum;
  volatile unsigned int L;
  volatile unsigned int i, j;
  unsigned int errors;

  errors = 0;
  for (k = 0; k<1000; k++){ //repeat memory test several times;
    //First, write to memory random numbers:
    //mprintf("memory_test_c#%d:\n Writing to memory...\n", k);
    Pointer16 = (unsigned short *)(SPARTAN_WRITE_MEMORY_BASE);
    csum=0;
    for(L=0; L<(int)128; L++)
    {
      //i = (k+1)*L;
      i = new_rand();
      i &= 0xffff;
      *Pointer16 = i;
      csum += i;
      Pointer16++;
    }

    //Now, read from memory random numbers:
    //mprintf("Reading from memory...\n");
    Pointer16 = (unsigned short *)(SPARTAN_READ_MEMORY_BASE);
    rcsum=0;
    for(i=0; i<(int)128; i++)
    {
      j = *Pointer16 & 0xffff;
      rcsum += j;
      Pointer16++;
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
  chan[0].state = CHANNEL_ACQUISITION; //Set initial correlator-channel status - "signal acquisition".
  chan[0].carrier_cold_corr = 0;       // ѕоправка к CARRIER_REF дл€ условно холодного поиска, когда есть информаци€ о текущей частоте доплера спутника.
  chan[0].carrier_freq = CARRIER_REF;

  chan[0].del_freq = 1;
  chan[0].n_freq = 0;

  program_TIC(0x007A11FF);       //set TIC-periode (0.1sec or 0.5sec?).
  program_accum_int(0x00009C3F); //set ACCUM_INT periode (0.0005sec = 0.5ms).


  ch_cntl (0, 16);               //set PRN number;
  ch_carrier(0, CARRIER_REF);    //set carrier freq;
  ch_code(0, CODE_REF);          //set code_generator clock freq;
}

/*** EOF ***/
