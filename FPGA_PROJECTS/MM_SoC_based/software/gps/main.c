/*
 * Milkymist SoC (Software)
 * Copyright (C) 2007, 2008, 2009, 2010, 2011 Sebastien Bourdeauducq
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#define MAIN

#include <stdio.h>
#include <console.h>
#include <string.h>
#include <uart.h>
#include <irq.h>
#include <hw/fmlbrg.h>
#include "./correlator/correlator.h"
#include "./isrl/isrl.h"

#include "./include/globals.h"


#define PIN_MASK	(1<<7)    // Interrupt signal from correlator comes to this pin.
#define FIO0PIN		(*(volatile unsigned int *)(0x60001000))

#define LED00		(*(volatile unsigned int *)(1610616836))

/******************************************************************************
FUNCTION reset_all_correlator_channels(void)
RETURNS  None.

PARAMETERS None.

PURPOSE
        This function resets the state of all correlator's channels.

WRITTEN BY
        Artyom Gavrilov.

******************************************************************************/
void reset_all_correlator_channles(void)
{
  int ch;

  // Assign PRN to channels and other initializing stuff:
  for (ch=0; ch < N_CHANNELS; ch++) {
    ch_cntl(ch, 0);              // Turn off all channels (by setting "0" as PRN number to generate. For details look comments in "Sim_GP2021_int" function).
    ch_carrier(ch, 0/*gps_carrier_ref*/); // Set default control-word to carrier NCO.
    ch_code(ch, 0/*gps_code_ref*/);       // Set default control-word to clock frequency of code NCO.
    chan[ch].state = CHANNEL_ACQUISITION; // Set the state of the channel to "acquisition".
    chan[ch].carrier_cold_corr = 0;       // Поправка к carrier_ref для условно холодного поиска, когда есть информация о текущей частоте доплера спутника.
    chan[ch].del_freq = 1;
    chan[ch].n_freq = 0;
    chan[ch].search_max_PRN_delay = 2045; // PRN delay search range in half-chips (2045 for GPS, 1021 for GLONASS).
    chan[ch].search_max_f = 5;            // Doppler search range in kHz.
    chan[ch].ms_set = 0;                        // ms counter is not synchronized.
  }
}

/******************************************************************************
FUNCTION simple_cold_allocate(void)
RETURNS  None.

PARAMETERS None.

PURPOSE
        This function initializes channels.

WRITTEN BY
        Artyom Gavrilov.

******************************************************************************/
void simple_cold_allocate(void)
{
  // set all channels to initial state:
  reset_all_correlator_channles();
  // turn on one channel:
  chan[0].prn = 20;               //
  ch_cntl(0, chan[0].prn);     	  // set PRN number for 1-st correlator channels.
  ch_carrier(0, gps_carrier_ref); // Set default control-word to carrier NCO.
  ch_code(0, gps_code_ref);       // Set default control-word to clock frequency of code NCO.

  chan[1].prn = 13;               //
  ch_cntl(1, chan[1].prn);
  ch_carrier(1, gps_carrier_ref);
  ch_code(1, gps_code_ref);

  /*chan[2].prn = 23;               //
  ch_cntl(2, chan[2].prn);
  ch_carrier(2, gps_carrier_ref);
  ch_code(2, gps_code_ref);

  chan[3].prn = 04;               //
  ch_cntl(3, chan[3].prn);
  ch_carrier(3, gps_carrier_ref);
  ch_code(3, gps_code_ref);*/
}

//====================================================================
void init_tracking_loops_parameter(void)
{
  calc_FLL_assisted_PLL_filter_loop_coefs(Bnp, Bnf, FLL_a_PLL_integ_time,
                                          &FLL_a_PLL_k1, &FLL_a_PLL_k2, &FLL_a_PLL_k3);
  convert_FLL_assisted_PLL_loop_filter_coefs_to_integer(FLL_a_PLL_k1, FLL_a_PLL_k2, FLL_a_PLL_k3,
                                                        &FLL_a_PLL_i1, &FLL_a_PLL_i2, &FLL_a_PLL_i3);
  calc_DLL_loop_filter_coefs(Bnd, DLL_integ_time, &DLL_k1, &DLL_k2);
  convert_DLL_loop_filter_coefs_to_integer(DLL_k1, DLL_k2, &DLL_i1, &DLL_i2);
}


//======main==========================================================

int main(int i, char **c)
{
  int a1, b1, a2, b2, c1, c2;

  int errors;			//number of errors during memory test.
  unsigned int PIN_STATUS;	//used to check pin_status. Thus emulating interrupt.

  int display_counter;

  //Some initialization: 
  irq_setmask(0);
  irq_enable(1);
  uart_init();

  // Initialize tracking loops parameters:
  init_tracking_loops_parameter();

  //Correlator initialization:
  correlator_init();

  //Correlator memory test:
  memory_test();

  //
  simple_cold_allocate();


  LED00=3;
  while ( 1 ) {	//endless cycle in which we always check interrupt request from correlator.
    if (FIO0PIN & 128){
      gpsisr();
      
      if (display_counter == 500){
        mprintf ("%c[%d;%dH", 0x1b, 2, 1);//goto x, y;
        mprintf("ch1: state=%d\t PRN=%d\t delay=%d\t Doppler=%5d\n", 
                chan[1].state, chan[1].prn, chan[1].codes, ( (chan[1].carrFreq - gps_carrier_ref)*2048/45813 ));
      }
      /*if (display_counter == 1000){
        mprintf ("%c[%d;%dH", 0x1b, 3, 1);//goto x, y;
        mprintf("ch2: state=%d\t PRN=%d\t delay=%d\t Doppler=%5d\n", 
                chan[2].state, chan[2].prn, chan[2].codes, ( (chan[2].carrFreq - gps_carrier_ref)*2048/45813 ));
      }
      if (display_counter == 1500){
        mprintf ("%c[%d;%dH", 0x1b, 4, 1);//goto x, y;
        mprintf("ch3: state=%d\t PRN=%d\t delay=%d\t Doppler=%5d\n", 
                chan[3].state, chan[3].prn, chan[3].codes, ( (chan[3].carrFreq - gps_carrier_ref)*2048/45813 ));
      }*/

      if (display_counter > 2000){  
        display_counter = 0;
        //mprintf("\n%c[2J", 0x1b);//clear screen;
        mprintf ("%c[%d;%dH", 0x1b, 1, 1);//goto x, y;
        mprintf("ch0: state=%d\t PRN=%d\t delay=%d\t Doppler=%5d\n", 
                chan[0].state, chan[0].prn, chan[0].codes, ( (chan[0].carrFreq - gps_carrier_ref)*2048/45813 ));
      }
      display_counter++;
    }
  }

	return 0;
}
