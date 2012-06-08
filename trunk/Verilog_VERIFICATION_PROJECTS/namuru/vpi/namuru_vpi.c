/*! \file namuru_vpi.c
*/
/* Copyright (c) 2011, Guy Hutchison
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
* Neither the name of the author nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include <stdio.h>
#include <stdlib.h>
#include <vpi_user.h>
#include <assert.h>
#include <string.h>
#include "namuru_vpi.h"

static FILE *ifdata; //file with record of GPS signal;

//================ GPS PROGRAM =========================================================================================
/* correlator channels numer */
#define N_CHANNELS 1
/* Carrier and code reference frequencies */
#define CODE_REF    0x015D2F1A  //code clock rate nominal frequency: (2.046e6*2^29)/48e6;
                                // 29 - number of bits in code_nco phase accumulator;
                                // (2.046e6 = 1.023e6*2) - doubled chip rate;
                                // 48e6 - correlator clock frequency;
#define CARRIER_REF 0x033A06D3  // carrier nominal frequency: (2.42e6*2^30)/48e6;
                                // 30 - number of bits in carrier_nco phase accumulator;
                                // 2.42e6 - nominal IF in rf-front-end;
                                // 48e6 - correlator clock frequency;
//#define D_FREQ 0x5761           //Doppler search step (1000Hz): (1000*2^30)/48e6;
#define D_FREQ 0x2BB0           //Doppler search step (500Hz): (1000*2^30)/48e6;

///static unsigned short astat;

/* GLOBAL VARIABLE! IT IS USED IN MAIN.C DURING INITIALIZATIONè! */
static struct tracking_channel chan[N_CHANNELS]; // array of structures that describe each correlator channel;

/* Next two variables should be unites in a structure. Each structure should be assigned to one channel. May be tracking_channel structure should be used? */
#define ACQ_THRESH 1600 //acquisition threshold (set empirically);
#define SEARCH_MAX_F 5  //Half of Doppler search range (in doppler step units: 2*5*1000 = 10000Hz);

#define CONFIRM_M      3   // Acquisition confirmation steps number;
#define N_OF_M_THRESH  2   // Required number of confirmations to move to pull-in process;

#define sign(x) (x > 0 ? 1 : (x == 0) ? 0 : -1) //function sign(x)

/* bit-manipulation functions */
#define  test_bit(bit_n, data) ((*((unsigned short *)(data))) &   (0x1 << (bit_n)))
#define   set_bit(bit_n, data) ((*((unsigned short *)(data))) |=  (0x1 << (bit_n)))
#define clear_bit(bit_n, data) ((*((unsigned short *)(data))) &= ~(0x1 << (bit_n)))

//test vectors for debugging:
#define TEST_VECTOR_MAX_LENGTH 10000
static int test_vectors_length;
static int test_vector_01[TEST_VECTOR_MAX_LENGTH];
static int test_vector_02[TEST_VECTOR_MAX_LENGTH];
static int test_vector_03[TEST_VECTOR_MAX_LENGTH];
static int test_vector_04[TEST_VECTOR_MAX_LENGTH];
static int test_vector_05[TEST_VECTOR_MAX_LENGTH];
static int test_vector_06[TEST_VECTOR_MAX_LENGTH];


//================ GPS PROGRAM END =====================================================================================

vpiHandle *get_args (int expected) {
  vpiHandle call_h, iref_h, arg_h;
  vpiHandle *alist;
  int hindex = 0;
  
  // allocate storage for handle list
  alist = (vpiHandle *) malloc (sizeof(vpiHandle) * expected);
  
  // get handles to argument list
 
  call_h = vpi_handle(vpiSysTfCall, NULL);
  assert ((iref_h = vpi_iterate(vpiArgument, call_h)) != NULL);

  while ((arg_h = vpi_scan(iref_h)) != NULL) {
    alist[hindex++] = arg_h;
  }

  if ((expected != -1) && (hindex != expected)) {
    vpi_printf ("PLI ERROR: expected %d arguments, got %d\n", expected, hindex);
  }
  return alist;
}

int inline getIntegerArgument (vpiHandle vh)
{
  s_vpi_value arg_info;

  arg_info.format = vpiIntVal;
  vpi_get_value (vh, &arg_info);
  return arg_info.value.integer;
}

inline char *getStringArgument (vpiHandle vh)
{
  s_vpi_value arg_info;
  char *buf;

  arg_info.format = vpiStringVal;
  vpi_get_value(vh, &arg_info);
  buf = (char *) malloc (sizeof(arg_info.value.str)+1);
  strcpy (buf, arg_info.value.str);

  return buf;
}

void inline putIntegerArgument (vpiHandle vh, int a)
{
  s_vpi_value arg_info;
  
  arg_info.format = vpiIntVal;
  arg_info.value.integer = a;
  vpi_put_value (vh, &arg_info, NULL, vpiNoDelay);
}


/*! \brief Open file for reading
*
* Usage: $gps_file_open (filename)
*
* Opens file with gps signal record for reading.
* filename - name of the file for opening;
* #TODO: Add protection for opening file twice (or more times).
*/
void gps_file_open () {
  vpiHandle *args;
  char *filename;
   
  args = get_args (1);
  filename = getStringArgument (args[0]);
    
  if ((ifdata=fopen(filename, "rb")) == NULL) {
    vpi_printf ("Error: Unable to open IF file %s\n", filename);
  }
  
  free (filename);
}

/*! \brief Close file previously opened with 'gps_file_open' function
*
* Usage: $gps_file_close ()
*
* Close file previously opened with 'gps_file_open' function.
* #TODO: Add protection for closing not opend file.
*/
void gps_file_close () {
  fclose(ifdata);
}


/*! \brief Read sample from file previously opened with 'gps_file_open' function
*
* Usage: $gps_read_sample (sample)
*
* Reads one sample from previously opened file.
* #TODO: Reading one sample per function call is not optimal.
* Block reading (reading block (several samples) of data) must be done!
*/
/*void gps_read_sample () { //Doesn't work during long simulation (>2ms)
  vpiHandle *args;
  int sample;
  char IF;
   
  args = get_args (1);
  //read sample from file:
  ///fread(&IF, sizeof(char), 1, ifdata);
  ///sample = IF;
  sample = -3;//temp
  //send sample to verilog-code:
  putIntegerArgument (args[0], sample);
}*/
// Implements the increment system task
//static int increment(char *userdata) {
static int gps_read_sample () { //This simple implementation taken from wiki works fine during long simulation (100 ms checked)
  vpiHandle systfref, args_iter, argh;
  struct t_vpi_value argval;
  int value;
  
  char IF;
 
  // Obtain a handle to the argument list
  systfref = vpi_handle(vpiSysTfCall, NULL);
  args_iter = vpi_iterate(vpiArgument, systfref);
 
  // Grab the value of the first argument
  argh = vpi_scan(args_iter);
  argval.format = vpiIntVal;
  vpi_get_value(argh, &argval);
  value = argval.value.integer;
 
  // Increment the value and put it back as first argument
  fread(&IF, sizeof(char), 1, ifdata);
  argval.value.integer = IF;
  vpi_put_value(argh, &argval, NULL, vpiNoDelay);
 
  // Cleanup and return
  vpi_free_object(args_iter);
  return 0;
}


//================ GPS PROGRAM =========================================================================================
/******************************************************************************
FUNCTION abs()
RETURNS  .

PARAMETERS .

PURPOSE
           Take absolute value of the number.


WRITTEN BY

        Gavrilov Artyom.



******************************************************************************/
/*long
abs (long x)
{
	if (x < 0)
		return -x;
	else
		return x;
}*/

long labs (long x) {
	if (x < 0)
		return -x;
	else
		return x;
}

/******************************************************************************
FUNCTION output_tst_data()
RETURNS  None.

PARAMETERS None.

PURPOSE
           Output test data!.

WRITTEN BY
        Clifford Kelley. Updated by Gavrilov Artyom.

******************************************************************************/
static void output_test_data () {
  int i;

  for(i=0; i<test_vectors_length; i++)
   vpi_printf("%d\t%d\t%d\t%d\t%d\t%d\n", test_vector_01[i], test_vector_02[i],
                                          test_vector_03[i], test_vector_04[i],
                                          test_vector_05[i], test_vector_06[i]);
}

/******************************************************************************
FUNCTION rss(long a, long b)
RETURNS  long integer

PARAMETERS
      a  long integer
      b  long integer

PURPOSE
        This function finds the fixed point magnitude of a 2 dimensional vector

WRITTEN BY
        Clifford Kelley

******************************************************************************/
static int rss (int a, int b) {
  int result, c, d;
  c = abs (a);
  d = abs (b);
  if ( (c == 0) && (d == 0) )
    result = 0;
  else {
    if (c > d)
      result = (d >> 1) + c;
    else
      result = (c >> 1) + d;
  }
  return (result);
}

/******************************************************************************
FUNCTION fix_sqrt(long x)
RETURNS  long integer

PARAMETERS
      x long integer

PURPOSE
        This function finds the fixed point square root of a long integer

WRITTEN BY
        Clifford Kelley

******************************************************************************/
static long fix_sqrt (long x) {
  long xt, scr;
  int i;
  i = 0;
  xt = x;
  do {
    xt = xt >> 1;
    i++;
  }
  while (xt > 0);
  i = (i >> 1) + 1;
  xt = x >> i;
  do {
    scr = xt * xt;
    scr = x - scr;
    scr = scr >> 1;
    scr = scr / xt;
    xt = scr + xt;
  }
  while (scr != 0);
  xt = xt << 7;
  return (xt);
}

/******************************************************************************
FUNCTION sqrt_newton(int x)
RETURNS  long integer

PARAMETERS
      x long integer

PURPOSE
        This function finds the fixed point square root of a long integer.

WRITTEN BY
        Íèêîëàé Ãàðáóç
        e-mail: nick@sf.demos.su
        http://algolist.manual.ru/maths/count_fast/intsqrt.php

******************************************************************************/
static unsigned sqrt_newton(long L) {
  long temp, divl;
  unsigned rslt = (unsigned)L;

  if (L <= 0)
    return 0;
  else
    if (L & 0xFFFF0000L)
      if (L & 0xFF000000L)
        divl = 0x3FFF;
      else
        divl = 0x3FF;
    else
      if (L & 0x0FF00L)
        divl = 0x3F;
      else divl = (L > 4) ? 0x7 : L;

  while (1) {
    temp = L/divl + divl;
    divl = temp >> 1;
    divl += temp & 1;
    if (rslt > divl)
      rslt = (unsigned)div;
    else {
        if (1/rslt == rslt-1 && 1%rslt==0)
          rslt--;
          return rslt;
    }
  }
}

/******************************************************************************
FUNCTION fix_atan2(long y,long x)
RETURNS  long integer

PARAMETERS
                x  long   in-phase fixed point value
                y  long   quadrature fixed point value

PURPOSE
      This function computes the fixed point arctangent represented by
      x and y in the parameter list
      1 radian = 16384
      based on the power series  f-f^3*2/9

WRITTEN BY
        Clifford Kelley
        Fixed for y==x added special code for x==0 suggested by Joel
        Barnes, UNSW
******************************************************************************/
static long fix_atan2 (long y, long x) {
  static long const SCALED_PI_ON_2 = 25736L;
  static long const SCALED_PI = 51472L;
  long result = 0, n, n3;
  if ((x == 0) && (y == 0))
    return (0);                 /* invalid case */

  if (x > 0 && x >= abs (y)) {
    n = (y << 14) / x;
    n3 = ((((n * n) >> 14) * n) >> 13) / 9;
    result = n - n3;
  }
  else if (x <= 0 && -x >= abs (y)) {
    n = (y << 14) / x;
    n3 = ((((n * n) >> 14) * n) >> 13) / 9;
    if (y > 0)
      result = n - n3 + SCALED_PI;
    else if (y <= 0)
      result = n - n3 - SCALED_PI;
  }
  else if (y > 0 && y > abs (x)) {
    n = (x << 14) / y;
    n3 = ((((n * n) >> 14) * n) >> 13) / 9;
    result = SCALED_PI_ON_2 - n + n3;
  }
  else if (y < 0 && -y > abs (x)) {
    n = (x << 14) / y;
    n3 = ((((n * n) >> 14) * n) >> 13) / 9;
    result = -n + n3 - SCALED_PI_ON_2;
  }
  return (result);
}

/******************************************************************************
FUNCTION ch_acq(char ch)
RETURNS  None.

PARAMETERS
                        ch  char

PURPOSE  to perform initial acquisition by searching code and frequency space
         looking for a high correllation

WRITTEN BY
        Clifford Kelley

******************************************************************************/
static void ch_acq (int ch, int *slew, int *carr_freq, int *code_freq) {
	long prompt_mag;
	struct tracking_channel *c = &chan[ch];
	
	*slew = 0; *carr_freq = 0; *code_freq = 0;///test

  if (abs (c->n_freq) <= SEARCH_MAX_F) { //search frequencies;
    prompt_mag = rss (c->accum.i_prompt, c->accum.q_prompt); //calculate prompt-magnitude;

    if (prompt_mag > ACQ_THRESH) {
      c->state = CHANNEL_CONFIRM; //start confirmation process;
      c->i_confirm = 0;
      c->n_thresh  = 0;
	  vpi_printf("ACQUISITION SUCCESS!!! NEXT STEP IS CONFIRMATION.\n\n");
    }
    else {
      ///ch_code_slew(ch, 1); //make half chip delay.
	  *slew = 1;///test
      c->codes += 1;
	  ///vpi_printf("NEXT DELAY STEP: %d\n", c->codes);
    }
    if (c->codes == 2044) {//all delays are passed for this Doppler bin so move to next one.
      c->n_freq += c->del_freq;
      c->del_freq = -(c->del_freq + sign (c->del_freq));
      c->carrier_freq = CARRIER_REF + c->carrier_cold_corr + D_FREQ * c->n_freq;
      ///ch_carrier (ch, c->carrier_freq);
	  *carr_freq = c->carrier_freq;///test
      c->codes = 0;
	  vpi_printf("NEXT DOPPLER BIN: %d \t DELAY STEP=%d \t CARR_FREQ=%d \n\n", c->n_freq, c->codes, c->carrier_freq);
    }
  }
  else {
    vpi_printf("RESET ACQUISITION\n\n"); //Start acquisition from the begining.
    c->n_freq   = 0;
    c->del_freq = 1;
    c->carrier_freq = CARRIER_REF + c->carrier_cold_corr;
    ///ch_carrier (ch, c->carrier_freq);
    c->codes = 0;
  }
}

/******************************************************************************
FUNCTION ch_confirm(char ch)
RETURNS  None.

PARAMETERS
                        ch  char  channel number

PURPOSE  to confirm the presence of a high correllation peak using an n of m
                        algorithm

WRITTEN BY
        Clifford Kelley

******************************************************************************/
static void ch_confirm (int ch, int *slew, int *carr_freq, int *code_freq) {
  int prompt_mag;
  struct tracking_channel *c = &chan[ch];
  
  *slew = 0; *carr_freq = 0; *code_freq = 0;///test

  prompt_mag = rss (c->accum.i_prompt, c->accum.q_prompt); //calculate prompt-magnitude;

  if (prompt_mag > ACQ_THRESH)
    c->n_thresh++;
  if (c->i_confirm == CONFIRM_M) {
    if (c->n_thresh >= N_OF_M_THRESH) {
      vpi_printf("CONFIRMATION SUCCESS!!! NEXT STEP IS PULL-IN.\n\n");
      c->state   = CHANNEL_PULL_IN;
      c->CN0     = 0;
      c->ch_time = 0;

      c->oldCarrNco    = c->oldCodeNco = c->oldCarrError = c->oldCodeError = 0;
      c->codeFreqBasis = CODE_REF;
      c->carrFreqBasis = c->carrier_freq;

      c->sign_pos = c->prev_sign_pos = 0;

      test_vectors_length = 0;        //test vectors are used during pull-in process. Before using them set their current length.
    }
    else {
      vpi_printf("CONFIRMATION FAIL! BACK TO ACQUISITION.\n\n");
      c->state = CHANNEL_ACQUISITION; //Confirmation failed! Go back to acquisition.
    }
  }
  c->i_confirm++;
}

/******************************************************************************
FUNCTION ch_pull_in(char ch)
RETURNS  None.

PARAMETERS
                        ch  char  channel number

PURPOSE
           pull in the frequency by trying to track the signal with a
           combination FLL and PLL

WRITTEN BY
        Clifford Kelley. Updated by Gavrilov Artyom.

******************************************************************************/
static void ch_pull_in (int ch, int *slew, int *carr_freq, int *code_freq) {
  ///long early_mag, late_mag;

  struct tracking_channel *c = &chan[ch];
  
  *slew = 0; *carr_freq = 0; *code_freq = 0;//test
  
  /* Code tracking loop: */
  if ( (c->accum.i_early!=0) && (c->accum.q_early!=0) && (c->accum.i_late!=0) &&(c->accum.q_late!=0) ){

    /*early_mag = sqrt_newton(c->accum.i_early*c->accum.i_early + c->accum.q_early*c->accum.q_early);
    late_mag  = sqrt_newton(c->accum.i_late *c->accum.i_late  + c->accum.q_late *c->accum.q_late );
    c->codeError = ((early_mag - late_mag) * 8192);
    c->codeError = c->codeError / (early_mag + late_mag);*/

    //DLL discriminator:
    c->codeError =                fix_sqrt(c->accum.i_early * c->accum.i_early + c->accum.q_early * c->accum.q_early);
    c->codeError = c->codeError - fix_sqrt(c->accum.i_late  * c->accum.i_late  + c->accum.q_late  * c->accum.q_late);
    c->codeError = (c->codeError * 8192);
    c->codeError = c->codeError / ( fix_sqrt(c->accum.i_early*c->accum.i_early + c->accum.q_early*c->accum.q_early) +
                                    fix_sqrt(c->accum.i_late*c->accum.i_late   + c->accum.q_late*c->accum.q_late));
  }
  else
    c->codeError = c->oldCodeError; //Temporary solution! Should be corrected!

  //DLL loop filter:
  c->codeNco = c->oldCodeNco + ((36*c->codeError - 35*c->oldCodeError) / 8192 );
  c->oldCodeNco   = c->codeNco;
  c->oldCodeError = c->codeError;

  c->codeFreq = c->codeFreqBasis - c->codeNco;
  /* Code tracking loop - END. */

  // Send control-word in correlator. Uppdate PRN code-rate:
  ///ch_code(ch, c->codeFreq);
  *code_freq = c->codeFreq;///test


  /* phase+frequency tracking loop: */
  if ( (c->accum.i_prompt!=0) && (c->accum.q_prompt!=0) && (c->prev2_accum.i_prompt!=00) && (c->prev2_accum.i_prompt!=0) ){
    c->cross = c->accum.i_prompt*c->prev2_accum.q_prompt - c->prev2_accum.i_prompt*c->accum.q_prompt;
    c->dot   = labs(c->accum.i_prompt*c->prev2_accum.i_prompt + c->accum.q_prompt*c->prev2_accum.q_prompt);

    /* test code (to overcome overflow): */
    c->cross = c->cross >> 8;
    c->dot   = c->dot   >> 8;
    /* test code - END */

    //frequency discriminator:
    c->freqError = fix_atan2(c->cross, c->dot);
    //phase discriminator:
    c->carrError = fix_atan2( (c->accum.q_prompt*sign(c->accum.i_prompt)), labs(c->accum.i_prompt) ) / 2;
  }
  else {
    c->freqError = 0;               //Temporary solution! Should be corrected!
    c->carrError = c->oldCarrError; //Temporary solution! Should be corrected!
  }

  //FLL-assisted PLL loop filter:
  c->carrNco =  c->oldCarrNco + ((925)* c->carrError - (895)* c->oldCarrError - (75)* c->freqError)/51472;

  c->oldCarrNco   = c->carrNco;
  c->oldCarrError = c->carrError;

  c->carrFreq = c->carrFreqBasis + c->carrNco;
  /* phase+frequency tracking loop - END. */

  // Send control-word in correlator. Update carrier frequency:
  ///ch_carrier(ch, c->carrFreq);
  *carr_freq = c->carrFreq;///test


  if ( sign(c->accum.i_prompt) == -sign(c->prev2_accum.i_prompt) ) { //detect bits edges according to sign change of prompt in-phase correlator output.
    c->prev_sign_pos = c->sign_pos;
    c->sign_pos = c->ch_time;

    if ( (c->sign_pos - c->prev_sign_pos) > 19 ) // Bits edges always multiples of 20ms.
                                                 // (Here we use simplified check: each bit should last more then 19 ms).
      c->sign_count++;
    else
      c->sign_count = 0;
  }


  //Debug info:
  if ( (c->ch_time < TEST_VECTOR_MAX_LENGTH) ) {
    test_vectors_length++;
    test_vector_01[c->ch_time] = c->accum.i_early;
    test_vector_02[c->ch_time] = c->accum.q_early;
    test_vector_03[c->ch_time] = c->accum.i_prompt;
    test_vector_04[c->ch_time] = c->accum.q_prompt;
    test_vector_05[c->ch_time] = c->accum.i_late;
    test_vector_06[c->ch_time] = c->accum.q_late;
  }


  c->ch_time++;

  if ( (c->sign_count > 30) ) { // pull-in condition. Here we count how many times bits lasted more then 19 ms. This method seems bad but it works.
    vpi_printf("YESSSSSSS!!!!!!!!!!\n\n\n\n");
    output_test_data(); //Output debug data through RS-232.
    c->state = CHANNEL_BIT_SYNC;
    vpi_printf("YESSSSSSS!!!!!!!!!!\n\n\n\n");
  }

  if (c->ch_time == 3000) {    // Pull-in process lasts not more then 3 seconds. If 3 seconds passed and lock is not achieved then acquisition process starts from the beginnig.
    vpi_printf("Acquisition failed!!!\n\n");
    output_test_data(); //Output debug data through RS-232.
    c->state = CHANNEL_ACQUISITION;
  }

}

/******************************************************************************
FUNCTION GPS_Interrupt()

RETURNS  None.

PARAMETERS ie, qe, ip, qp, il, ql, slew, carr_freq, code_freq.

PURPOSE
        This function replaces the current IRQ0 Interrupt service
        routine with our GPS function which will perform the
        acquisition - tracking functions

WRITTEN BY
        Clifford Kelley

******************************************************************************/
/*void gpsisr (void) {
  unsigned short status;
  int ch;

  status = get_status();

  astat = accum_status (); // check what channels are ready to output data from correlators;
  clear_new_data();        // clear astat-value in correlator;

  for (ch = 0; ch < N_CHANNELS; ch++) {
    struct tracking_channel *c = &chan[ch];
    if (test_bit (ch, (void *)&astat)) {
      c->prev2_accum = c->accum; //Save previous correlator accumulators values (they are used in FLL).

      //read correlator accumulators for current channel:
      c->accum.i_early   = ch_i_early(ch);
      c->accum.q_early   = ch_q_early(ch);
      c->accum.i_prompt  = ch_i_prompt(ch);
      c->accum.q_prompt  = ch_q_prompt(ch);
      c->accum.i_late    = ch_i_late(ch);
      c->accum.q_late    = ch_q_late(ch);
    }
  }


  for (ch = 0; ch < N_CHANNELS; ch++) {
    if (test_bit (ch, (void *)&astat)) {
      switch (chan[ch].state) {
      case CHANNEL_OFF:
        break;
      case CHANNEL_ACQUISITION:
        ch_acq(ch);
        break;
      case CHANNEL_CONFIRM:
        ch_confirm(ch);
        break;
      case CHANNEL_PULL_IN:
        ch_pull_in(ch);
        break;
      case CHANNEL_BIT_SYNC:
        break;
      case CHANNEL_LOCK:
        break;
      }
    }
  }
  clear_status(); //drop interrupt signal in correlator.
}*/

static int gpsisr(){
	vpiHandle systfref, args_iter;//, argh;
	struct t_vpi_value argval;
///	int value;
	
	vpiHandle argh0, argh1, argh2, argh3;
	vpiHandle argh4, argh5, argh6, argh7, argh8;
	
	int ie, qe, ip, qp, il, ql;
	int slew, carr_freq, code_freq;
	static int ch = 0;
	
	struct tracking_channel *c = &chan[ch];
	
	slew = 0; carr_freq = 0; code_freq = 0;

	//==== Get data from verilog ==================
	// Obtain a handle to the argument list
	systfref = vpi_handle(vpiSysTfCall, NULL);
	args_iter = vpi_iterate(vpiArgument, systfref);
 
	//Get arguments pointers (?)
	argh0 = vpi_scan(args_iter);
	argh1 = vpi_scan(args_iter);
	argh2 = vpi_scan(args_iter);
	argh3 = vpi_scan(args_iter);
	argh4 = vpi_scan(args_iter);
	argh5 = vpi_scan(args_iter);
	argh6 = vpi_scan(args_iter);
	argh7 = vpi_scan(args_iter);
	argh8 = vpi_scan(args_iter);
	
	//Set argument type (?)
	argval.format = vpiIntVal;
	
	//Get arguments values (?)
	vpi_get_value(argh0, &argval);
	ie = (signed short)argval.value.integer;
	vpi_get_value(argh1, &argval);
	qe = (signed short)argval.value.integer;
	vpi_get_value(argh2, &argval);
	ip = (signed short)argval.value.integer;
	vpi_get_value(argh3, &argval);
	qp = (signed short)argval.value.integer;
	vpi_get_value(argh4, &argval);
	il = (signed short)argval.value.integer;
	vpi_get_value(argh5, &argval);
	ql = (signed short)argval.value.integer;
	
	//save previous values to prev2_accum before loading new values from 6 correlators:
	c->prev2_accum = c->accum;
	//Transmit received values to structure:
	c->accum.i_early  = ie;
	c->accum.q_early  = qe;
	c->accum.i_prompt = ip;
	c->accum.q_prompt = qp;
	c->accum.i_late   = il;
	c->accum.q_late   = ql;
	
	switch (chan[ch].state) {
		case CHANNEL_OFF:
			break;
		case CHANNEL_ACQUISITION:
			ch_acq(ch, &slew, &carr_freq, &code_freq);
			break;
		case CHANNEL_CONFIRM:
			ch_confirm(ch, &slew, &carr_freq, &code_freq);
			break;
		case CHANNEL_PULL_IN:
			ch_pull_in(ch, &slew, &carr_freq, &code_freq);
			break;
		case CHANNEL_BIT_SYNC:
			break;
		case CHANNEL_LOCK:
			break;
	}
	
	//======== Return values to verilog =================
	// Increment the value and put it back
	argval.value.integer = slew;
	vpi_put_value(argh6, &argval, NULL, vpiNoDelay);
	argval.value.integer = carr_freq;
	vpi_put_value(argh7, &argval, NULL, vpiNoDelay);
	argval.value.integer = code_freq;
	vpi_put_value(argh8, &argval, NULL, vpiNoDelay);
	
	// Cleanup and return
	vpi_free_object(args_iter);
	
	//for debug purposes:
	//vpi_printf("ie=%d\tqe=%d\tip=%d\tqp=%d\til=%d\tql=%d\tslew=%d\tcarr_f=%d\tcode_f=%d\n", 
	//ie, qe, ip, qp, il, ql, slew, carr_freq, code_freq);//for testing;
	vpi_printf("%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n", 
	ie, qe, ip, qp, il, ql, slew, carr_freq, code_freq);//for testing;
	
	return 0;
  
}

/******************************************************************************
FUNCTION init_gpsisr()
RETURNS  None.

PARAMETERS  None.

PURPOSE  Initialize all required data

WRITTEN BY
        Artyom Gavrilov

******************************************************************************/
void gpsisr_init(void){
///  unsigned int mask;

  chan[0].state = CHANNEL_ACQUISITION;	//Set initial correlator-channel 
										//status - "signal acquisition".
  chan[0].carrier_cold_corr = 0;	//Correction for CARRIER_REF when 
									//apriori information about 
									//satellite Doppler.
  chan[0].carrier_freq = CARRIER_REF;
  chan[0].del_freq = 1;
  chan[0].n_freq = 0;
  
  ///vpi_printf("init_gpsisr call DONE!\n\n");//for testing;
}

//================ GPS PROGRAM END =====================================================================================


// Register VPI routines with the simulator
extern void pv_register(void)
{
  p_vpi_systf_data systf_data_p;
 
  /* use predefined table form - could fill systf_data_list dynamically */
  static s_vpi_systf_data systf_data_list[] = {

	{ vpiSysTask, 0, "$gps_file_open",   gps_file_open,   NULL, NULL, NULL },
    { vpiSysTask, 0, "$gps_file_close",  gps_file_close,  NULL, NULL, NULL },
    { vpiSysTask, 0, "$gps_read_sample", gps_read_sample, NULL, NULL, NULL },
	{ vpiSysTask, 0, "$gpsisr_init",     gpsisr_init,     NULL, NULL, NULL },
	{ vpiSysTask, 0, "$gpsisr",          gpsisr,          NULL, NULL, NULL },
    { 0, 0, NULL, NULL, NULL, NULL, NULL }
  };
  
  systf_data_p = &(systf_data_list[0]);
  while (systf_data_p->type != 0) vpi_register_systf(systf_data_p++);
}

// entry point for simulator
void (*vlog_startup_routines[]) () = { pv_register, 0 };