/*
 ============================================================================
 Name        : osgnss_next_step.c
 Author      : Gavrilov Artyom
 Version     : 0.1
 Copyright   : GPLv3 source code
 Description : GNSS receiver based on OSGPS source code.
 ============================================================================
 */
#define MAIN
#include ".\include\globals.h"
#include <stdio.h>
#include <string.h> /* in order to use "strncpy" function */
#include <getopt.h> /* in order to use "optarg" variable */
#include <stdlib.h> /* in order to use "EXIT_FAILURE" */
#include <sys/stat.h>
#include ".\correlator\correlator.h"
#include ".\isr\osgpsisr.h"
#include ".\gp2021\gp2021.h"
#include ".\display\display.h"

#ifndef FILENAME_MAX
#define FILENAME_MAX 256
#endif
#define DEFAULT_FILENAME "gnss.bin"


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
    ch_carrier(ch, gps_carrier_ref); // Set default control-word to carrier NCO.
    ch_code(ch, gps_code_ref);       // Set default control-word to clock frequency of code NCO.
    chan[ch].state = CHANNEL_ACQUISITION; // Set the state of the channel to "acquisition".
    chan[ch].carrier_cold_corr = 0;       // Поправка к carrier_ref для условно холодного поиска, когда есть информация о текущей частоте доплера спутника.
    chan[ch].del_freq = 1;
    chan[ch].n_freq = 0;
    chan[ch].search_max_PRN_delay = 2045; // PRN delay search range in half-chips (2045 for GPS, 1021 for GLONASS).
    chan[ch].search_max_f = 5;            // Doppler search range in kHz.
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
  ch_cntl(0, 27);       //set PRN number for 1-st correlator channels.
  ch_cntl(8, 9);
}

/******************************************************************************
FUNCTION init_tracking_loops_parameter(void)
RETURNS  None.

PARAMETERS None.

PURPOSE
        This function initializes channels.

WRITTEN BY
        Artyom Gavrilov.

******************************************************************************/
void init_tracking_loops_parameter(void)
{
  calc_FLL_assisted_PLL_filter_loop_coefs(Bnp, Bnf, FLL_a_PLL_integ_time,
                                          &FLL_a_PLL_k1, &FLL_a_PLL_k2, &FLL_a_PLL_k3);
  convert_FLL_assisted_PLL_loop_filter_coefs_to_integer(FLL_a_PLL_k1, FLL_a_PLL_k2, FLL_a_PLL_k3,
                                                        &FLL_a_PLL_i1, &FLL_a_PLL_i2, &FLL_a_PLL_i3);
  calc_DLL_loop_filter_coefs(Bnd, DLL_integ_time, &DLL_k1, &DLL_k2);
  convert_DLL_loop_filter_coefs_to_integer(DLL_k1, DLL_k2, &DLL_i1, &DLL_i2);
}


/*================================= MAIN ====================================*/

int main (int argc, char *argv[])
{
  FILE *ifdata;         // file with GPS signal record.
  char IF[(int)SAMP_RATE/1000*2]; // array with GPS signal samples to be processed.
                                  // The size is chosen in order to store 1ms of IQ-data.
                                  // (It is twice of the size required to store only I-data).
  char IF_Filename[FILENAME_MAX]; // Name of the file with GPS signal record.

  long nsamp;           // number of samples per interrupt.
  int opt;              // variable used to separate command line parameters.
  int idispcnt = 0;     // counter variable. Used to call display()-function every 25 correlator interrupt.

  // Clear console screen:
  clear_screen();

  // Initialize tracking loops parameters:
  init_tracking_loops_parameter();

  // Set default filename of the file with GPS signal record:
  strncpy (IF_Filename, DEFAULT_FILENAME, 8);
  // Command line parameters separation:
  while ((opt = getopt(argc, argv, "3pf:t:u")) != -1) {
    switch (opt) {
    case 'f':
      strncpy (IF_Filename, optarg, FILENAME_MAX);
      break;
    case 'i':
      use_iq_processing = 0;
    default: /* '?' */
      fprintf (stderr, "Usage: %s [-f filename]\n", argv[0]);
      exit (EXIT_FAILURE);
    }
  }

  // Correlator initialization:
  correlator_init (tic_period);

  // number of samples per interrupt:
  nsamp = SAMP_RATE * interr_int / 1.0e6;

  // Create file to write debug data:
  if ( (corr_out = fopen("e:\\corr_out.csv", "w"))==NULL ) {
    fprintf(stderr, "Error creating file corr_out.csv");
    exit(EXIT_FAILURE);
  }

  /* Open input from a standard file that contains GPS signal record: */
  if ((ifdata=fopen(IF_Filename,"rb")) == NULL) {
    fprintf (stderr, "Error: Unable to open IF file %s: %s\n", IF_Filename, strerror (errno));
    fprintf (stderr, "Exiting...\n");
    exit (EXIT_FAILURE);
  }

  simple_cold_allocate();

  // Data processing loop:
  while (!feof(ifdata)) {
    // Read next portion of data from the file
    // (if IQ-processing is used then 2*nsamp samples are read,
    // if only I-processing is used then 1*nsamp samples are read):
    fread(&IF, sizeof(char), (use_iq_processing+1)*nsamp, ifdata);
    // Software correlator call:
    Sim_GP2021_int(IF, nsamp);
    // Interrupt processing (tracking loops etc.):
    gpsisr();

    if (idispcnt > 25) { // Call display()-function every 25 cycle.
      if (display()!=0) break;
      idispcnt = 0;
    }
    else idispcnt++;

  }
  return 0;
}
