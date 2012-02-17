#include <stdint.h>
#include ".\..\correlator\correlator.h"
#include "osgpsisr.h"
#include ".\..\gp2021\gp2021.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include ".\..\include\globals.h"

//test vectors for debugging:
#define DEBUG_TRACKING
#ifdef DEBUG_TRACKING
#define TEST_VECTOR_MAX_LENGTH 10000
static int test_vectors_length;
static int test_vector_01[TEST_VECTOR_MAX_LENGTH];
static int test_vector_02[TEST_VECTOR_MAX_LENGTH];
static int test_vector_03[TEST_VECTOR_MAX_LENGTH];
static int test_vector_04[TEST_VECTOR_MAX_LENGTH];
static int test_vector_05[TEST_VECTOR_MAX_LENGTH];
static int test_vector_06[TEST_VECTOR_MAX_LENGTH];
#endif

#define sign(x) (x > 0 ? 1 : (x == 0) ? 0 : -1) // sign(x) function definition.

// bit manipulation functions:
#define  test_bit(bit_n, data) ((*((uint16_t *)(data))) &   (0x1 << (bit_n)))
#define   set_bit(bit_n, data) ((*((uint16_t *)(data))) |=  (0x1 << (bit_n)))
#define clear_bit(bit_n, data) ((*((uint16_t *)(data))) &= ~(0x1 << (bit_n)))

static void ch_acq (int);
static void ch_confirm (int);
static void ch_pull_in (int);

/******************************************************************************
FUNCTION output_test_data()
RETURNS  None.

PARAMETERS None.

PURPOSE
           Output test data!. Platform specific function!

WRITTEN BY
        Gavrilov Artyom.

******************************************************************************/
#ifdef DEBUG_TRACKING
static void output_test_data ()
{
  int i;

  for(i=0; i<test_vectors_length; i++)
    fprintf(corr_out, "%d\t%d\t%d\t%d\t%d\t%d\n",
            test_vector_01[i], test_vector_02[i],
            test_vector_03[i], test_vector_04[i],
            test_vector_05[i], test_vector_06[i]);
}
#endif

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
static long rss (long a, long b)
{
  long result, c, d;
  c = abs (a);
  d = abs (b);
  if (c == 0 && d == 0)
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
static long fix_sqrt (long x)
{
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
        Функция вычисляет целочисленное значение квадратного кореня.

WRITTEN BY
        Николай Гарбуз
        e-mail: nick@sf.demos.su
        http://algolist.manual.ru/maths/count_fast/intsqrt.php

******************************************************************************/
static unsigned sqrt_newton(long L)
{
  long temp, div;
  unsigned rslt = (unsigned)L;

  if (L <= 0)
    return 0;
  else
    if (L & 0xFFFF0000L)
      if (L & 0xFF000000L)
        div = 0x3FFF;
      else
        div = 0x3FF;
    else
      if (L & 0x0FF00L)
        div = 0x3F;
      else div = (L > 4) ? 0x7 : L;

  while (1) {
    temp = L/div + div;
    div = temp >> 1;
    div += temp & 1;
    if (rslt > div)
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
static long fix_atan2 (long y, long x)
{
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
FUNCTION calc_FLL_assisted_PLL_loop_filter_coefs(long pll_bw, long fll_bw, long integration_t, double *k1, double *k2, double *k3)
RETURNS  long integer

PARAMETERS
                pll_bw  long   phased locked loop noise bandwidth [Hz]
                fll_bw  long   frequency locked loop noise bandwidth [Hz]
                int_t   long   integration period [ms]
                *k1, *k2, *k3 double   loop filer coefficients

PURPOSE
      This function computes FLL-assisted-PLL loop filter coefficients.
      Refer to "Understanding GPS. Principles and Applications. Second edition"
      by Elliott D. Kaplan, Christopher J. Hegarty. 2006.
      pp. 179-183.

WRITTEN BY
        Gavrilov Artyom
******************************************************************************/
void calc_FLL_assisted_PLL_filter_loop_coefs(long pll_bw, long fll_bw, long integration_t, double *k1, double *k2, double *k3)
{
  double wnp, wnf;
  double T;
  double a2;

  wnp = pll_bw / 0.53;
  wnf = fll_bw / 0.25;
  T = (double)integration_t / 1000;
  a2 = 1.414;

  *k1 = T*(wnp*wnp) + a2*wnp;
  *k2 = a2*wnp;
  *k3 = T*wnf;
}

/******************************************************************************
FUNCTION convert_FLL_assisted_PLL_loop_filter_coefs_to_integer(double k1, double k2, double k3, int *i1, int *i2, int *i3)
RETURNS  long integer

PARAMETERS
                k1, k2, k3  FLL-assisted-PLL loop filter coefficients [double values]
                i1, i2, i3  FLL-assisted-PLL loop filter coefficients [integer values]

PURPOSE
      This function converts double values to integer values. It takes into consideration
      carrier NCO frequency resolution.

WRITTEN BY
        Gavrilov Artyom
******************************************************************************/
void convert_FLL_assisted_PLL_loop_filter_coefs_to_integer(double k1, double k2, double k3, int *i1, int *i2, int *i3)
{
  *i1 = (int) (  k1 * ((1<<CARRIER_NCO_DIGIT_CAPACITY) / (SAMP_RATE*SYSTEM_CLOCK_MULTIPLIER))  );
  *i2 = (int) (  k2 * ((1<<CARRIER_NCO_DIGIT_CAPACITY) / (SAMP_RATE*SYSTEM_CLOCK_MULTIPLIER))  );
  *i3 = (int) (  k3 * ((1<<CARRIER_NCO_DIGIT_CAPACITY) / (SAMP_RATE*SYSTEM_CLOCK_MULTIPLIER))  );
}

/******************************************************************************
FUNCTION calc_DLL_loop_filter_coefs(long dll_bw, long integration_t, double *k1, double *k2)
RETURNS  long integer

PARAMETERS
                dll_bw  long   delay locked loop noise bandwidth [Hz]
                int_t   long   integration period [ms]
                *k1, *k2   double   loop filer coefficients

PURPOSE
      This function computes DLL loop filter coefficients (simple second
      order loop is used).
      Refer to "Understanding GPS. Principles and Applications. Second edition"
      by Elliott D. Kaplan, Christopher J. Hegarty. 2006.
      pp. 179-183.

WRITTEN BY
        Gavrilov Artyom
******************************************************************************/
void calc_DLL_loop_filter_coefs(long dll_bw, long integration_t, double *k1, double *k2)
{
  double w;
  double T;
  double a2;

  w = dll_bw / 0.53;
  T = (double)integration_t / 1000;
  a2 = 1.414;

  *k1 = T*(w*w) + a2*w;
  *k2 = a2*w;
}

/******************************************************************************
FUNCTION convert_DLL_loop_filter_coefs_to_integer(double k1, double k2, int *i1, int *i2)
RETURNS  long integer

PARAMETERS
                k1, k2, k3  FLL-assisted-PLL loop filter coefficients [double values]
                i1, i2, i3  FLL-assisted-PLL loop filter coefficients [integer values]

PURPOSE
      This function converts double values to integer values. It takes into consideration
      carrier NCO frequency resolution.

WRITTEN BY
        Gavrilov Artyom
******************************************************************************/
void convert_DLL_loop_filter_coefs_to_integer(double k1, double k2, int *i1, int *i2)
{
  *i1 = (int) (  k1 * ((1<<CODE_NCO_DIGIT_CAPACITY) / (SAMP_RATE*SYSTEM_CLOCK_MULTIPLIER))  );
  *i2 = (int) (  k2 * ((1<<CODE_NCO_DIGIT_CAPACITY) / (SAMP_RATE*SYSTEM_CLOCK_MULTIPLIER))  );
}

/******************************************************************************
FUNCTION GPS_Interrupt()

RETURNS  None.

PARAMETERS None.

PURPOSE
        This function replaces the current IRQ0 Interrupt service
        routine with our GPS function which will perform the
        acquisition - tracking functions

WRITTEN BY
        Clifford Kelley

******************************************************************************/
void gpsisr (void)
{
  int ch;
  int astat;

  //a_missed = gp2021_missed ();   // did we miss any correlation data.
  astat = accum_status ();         // get info on what channels have data ready.
  for (ch = 0; ch < N_CHANNELS; ch++) {
    tracking_channel *c = &chan[ch];
    if (test_bit (ch, (void *) &astat)) {
      c->prev_accum      = c->accum;          // Remember previous accumulators values.
      c->accum.i_early   = ch_i_early(ch);    // inphase early.
      c->accum.q_early   = ch_q_early(ch);    // quadrature early.
      c->accum.i_prompt  = ch_i_prompt(ch);   // inphase prompt.
      c->accum.q_prompt  = ch_q_prompt(ch);   // quadrature prompt.
      c->accum.i_late    = ch_i_late(ch);     // inphase late.
      c->accum.q_late    = ch_q_late(ch);     // quadrature late.
    }
  }

  for (ch = 0; ch < N_CHANNELS; ch++) {
    if (test_bit (ch, (void *) &astat)) {
      switch (chan[ch].state) {
      case CHANNEL_OFF:
        //printf("CHANNEL_OFF IS NOT REALIZED YET!\n\n");
        exit(0);
        break;
      case CHANNEL_ACQUISITION:
        //printf ("Acquisition process in chanel# ch %d \n", ch);
        ch_acq(ch);
        break;
      case CHANNEL_CONFIRM:
        //printf ("Confirmation process in chanel# ch %d \n", ch);
        ch_confirm(ch);
        break;
      case CHANNEL_PULL_IN:
        //printf ("Pull-in process in chanel# ch %d \n", ch);
        //exit(0);
        ch_pull_in(ch);
        break;
      case CHANNEL_TRACKING:
        //printf("LOCK is archived!\n\n");
        //exit(0);
        break;
      }
    }
  }
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
static void ch_acq (int ch)
{
  long prompt_mag;
  tracking_channel *c = &chan[ch];

  if (abs (c->n_freq) <= c->search_max_f) { // search frequencies.
    prompt_mag = rss (c->accum.i_prompt, c->accum.q_prompt); //calculate prompt-magnitude.

    if (prompt_mag > acq_thresh) {
      c->state = CHANNEL_CONFIRM; //start confirmation process.
      c->i_confirm = 0;
      c->n_thresh = 0;
      /* test additions */
      c->accum_mean.early_mag = c->accum_mean.prompt_mag = c->accum_mean.late_mag = 0;
    }
    else {
      ch_code_slew (ch, 1); //make half chip delay.
      c->codes += 1;
    }
    if (c->codes == c->search_max_PRN_delay) { //all delays are passed for this Doppler bin so move to next one.
      c->n_freq += c->del_freq;
      c->del_freq = -(c->del_freq + sign (c->del_freq));
      c->carrier_freq = gps_carrier_ref + c->carrier_cold_corr + d_freq * c->n_freq;
      ch_carrier (ch, c->carrier_freq);
      c->codes = 0;
    }
  }
  else { //Start acquisition from the beginning:
    c->n_freq = 0;
    c->del_freq = 1;
    c->carrier_freq = gps_carrier_ref + c->carrier_cold_corr + d_freq * c->n_freq;
    ch_carrier (ch, c->carrier_freq);
    c->codes = 0;
  }
  c->CN0 = 0;
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
static void ch_confirm (int ch)
{
  long prompt_mag, early_mag, late_mag;
  tracking_channel *c = &chan[ch];

  prompt_mag = rss (c->accum.i_prompt, c->accum.q_prompt); // prompt_arm energy calculation.
  late_mag   = rss (c->accum.i_late,   c->accum.q_late  ); // late_arm   energy calculation.
  early_mag  = rss (c->accum.i_early,  c->accum.q_early ); // early_arm  energy calculation.

  c->accum_mean.early_mag  = c->accum_mean.early_mag  +  early_mag;
  c->accum_mean.prompt_mag = c->accum_mean.prompt_mag +  prompt_mag;
  c->accum_mean.late_mag   = c->accum_mean.late_mag   +  late_mag;

  if (prompt_mag > acq_thresh)
    c->n_thresh++;

  if (c->i_confirm == CONFIRM_M) {
    if (c->n_thresh >= N_OF_M_THRESH) {
      //test additions (Change PRN generator delay in order to make prompt code synchronous with incoming signal as much as possible):
      //if ( (c->accum_mean.early_mag > c->accum_mean.prompt_mag) && (c->accum_mean.early_mag > c->accum_mean.late_mag) )
      //  ch_code_slew(ch, 2);
      //if ( (c->accum_mean.late_mag > c->accum_mean.early_mag) && (c->accum_mean.late_mag > c->accum_mean.prompt_mag) )
      //        ch_code_slew(ch, 2044);

      c->state = CHANNEL_PULL_IN;
      c->CN0 = 0;
      c->ch_time = 0;

      c->oldCarrNco    = c->oldCodeNco = c->oldCarrError = c->oldCodeError = 0;
      c->codeFreqBasis = gps_code_ref;
      c->carrFreqBasis = c->carrier_freq;

      c->sign_pos = c->prev_sign_pos = 0;

      #ifdef DEBUG_TRACKING
      test_vectors_length = 0;        //test vectors are used during pull-in process. Before using them set their current length.
      #endif
    }
    else
      c->state = CHANNEL_ACQUISITION;
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
static void ch_pull_in (int ch)
{
  tracking_channel *c = &chan[ch];

  //===========phase+frequency tracking loop:==================================
  if ( (c->accum.i_prompt!=0) && (c->accum.q_prompt!=0) && (c->prev_accum.i_prompt!=00) && (c->prev_accum.q_prompt!=0) ){
    // calculate "cross" and "dot" values:
    c->cross = c->accum.i_prompt*c->prev_accum.q_prompt - c->prev_accum.i_prompt*c->accum.q_prompt;
    c->dot   = labs(c->accum.i_prompt*c->prev_accum.i_prompt + c->accum.q_prompt*c->prev_accum.q_prompt);

    // test code (to overcome overflow):
    c->cross = c->cross >> 8; //Temporary solution! Should be reworked in future!
    c->dot   = c->dot   >> 8; //Temporary solution! Should be reworked in future!
    // test code - END.

    // frequency discriminator:
    c->freqError = fix_atan2(c->cross, c->dot);
    // carrier discriminator:
    c->carrError = fix_atan2( (c->accum.q_prompt*sign(c->accum.i_prompt)), labs(c->accum.i_prompt) ) / 2;
  }
  else {
    c->freqError = 0;
    c->carrError = c->oldCarrError;
  }

  // closed loop filter:
  //TODO: WRITE FUNCTION THAT CALCULATES MAGIC NUMBER!!!
  c->carrNco =  c->oldCarrNco + (FLL_a_PLL_i1*c->carrError - FLL_a_PLL_i2*c->oldCarrError - FLL_a_PLL_i3*c->freqError)/51472;

  c->oldCarrNco   = c->carrNco;
  c->oldCarrError = c->carrError;

  //calculate final value:
  c->carrFreq = c->carrFreqBasis + c->carrNco;
  //===========phase+frequency tracking loop - END.============================

  //updating channel settings:
  ch_carrier(ch, c->carrFreq); // Set new carrier frequency.

  //===========code tracking loop:=============================================
  if ( (c->accum.i_early!=0) && (c->accum.q_early!=0) && (c->accum.i_late!=0) &&(c->accum.q_late!=0) ){
    // Code non-coherent discriminator:
    c->codeError =                sqrt_newton(c->accum.i_early * c->accum.i_early + c->accum.q_early * c->accum.q_early);
    c->codeError = c->codeError - sqrt_newton(c->accum.i_late  * c->accum.i_late  + c->accum.q_late  * c->accum.q_late);
    c->codeError = (8192)*c->codeError;
    c->codeError = c->codeError / ( (int)sqrt_newton(c->accum.i_early*c->accum.i_early + c->accum.q_early*c->accum.q_early) +
                                    (int)sqrt_newton(c->accum.i_late*c->accum.i_late   + c->accum.q_late*c->accum.q_late) );
  }
  else
    c->codeError = c->oldCodeError; // Temporary solution! Should be checked in future!

  // closed loop filter:
  //TODO: WRITE FUNCTION THAT CALCULATES MAGIC NUMBER!!!
  // (DLL_i1+1) is used instead of DLL_i1 because this way DLL works more stable! In theory DLL_i1 should be used.
  // Advanced research about stability issues of fixed point math is required!!!
  c->codeNco = c->oldCodeNco + ( ((DLL_i1+1)*c->codeError - (DLL_i2)*c->oldCodeError) / 8192 );

  c->oldCodeNco   = c->codeNco;
  c->oldCodeError = c->codeError;

  // calculate final value:
  c->codeFreq = c->codeFreqBasis - c->codeNco;
  //===========Code tracking loop - END.=======================================

  //updating channels settings:
  ch_code(ch, c->codeFreq); // Set new code clock frequency.

  //===========bits edges detection:===========================================
  // bits edges detection according to sign change of In-phase_PROMPT correlator channel output:
  if ( sign(c->accum.i_prompt) == -sign(c->prev_accum.i_prompt) ) {
    c->prev_sign_pos = c->sign_pos;
    c->sign_pos = c->ch_time;

    if ( (c->sign_pos - c->prev_sign_pos) > 19 ) // Bits edges are always multiple of 20 ms (20 ms for GPS and 10 ms for GLONASS).
                                                 //(Though noise process can also satisfy this condition...
                                                 // Стоило бы проверять именно кратность 20, а не превышение 19 (для GPS)!).
      c->sign_count++;
    else
      c->sign_count = 0;
  }
  //===========bits edges detection - END.=====================================

  //Debug info:
  #ifdef DEBUG_TRACKING
  if ( (c->ch_time < TEST_VECTOR_MAX_LENGTH) ) {
    test_vectors_length++;
    test_vector_01[c->ch_time] = c->accum.i_early;
    test_vector_02[c->ch_time] = c->accum.q_early;
    test_vector_03[c->ch_time] = c->accum.i_prompt;
    test_vector_04[c->ch_time] = c->accum.q_prompt;
    test_vector_05[c->ch_time] = c->accum.i_late;
    test_vector_06[c->ch_time] = c->accum.q_late;
  }
  #endif

  c->ch_time++;

  if ( (c->sign_count > 30) ) { // pull-in condition. Here we count how many times bits
                                // lasted more then 19 ms. This method seems bad but it works.
    output_test_data();
    c->state = CHANNEL_TRACKING;
    printf("c->carrFreqBasis = %lu", c->carrFreqBasis);
  }
  if (c->ch_time == 3000) {    // Pull-in process lasts not more then 3 seconds.
                               // If 3 seconds passed and lock is not achieved then
                               // acquisition process starts from the beginnig.
    c->state = CHANNEL_ACQUISITION;
  }

}
