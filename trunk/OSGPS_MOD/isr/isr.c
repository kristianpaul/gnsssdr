#include "LPC23xx.h"

#include "isr.h"
#include ".\gp2021\gp2021.h"
#include "mprintf\mprintf.h"
#include "correlator\correlator.h"

/* correlator channels numer */
#define N_CHANNELS 1
/* Carrier and code reference frequencies */
#define CODE_REF 0x00D182A9     //code clock rate nominal frequency: (2.046e6*2^29)/80e6;
                                // 29 - number of bits in code_nco phase accumulator;
                                // (2.046e6 = 1.023e6*2) - doubled chip rate;
                                // 80e6 - correlator clock frequency;
#define CARRIER_REF 0x01EF9DB2  // carrier nominal frequency: (2.42e6*2^30)/80e6;
                                // 30 - number of bits in carrier_nco phase accumulator;
                                // 2.42e6 - nominal IF in rf-front-end;
                                // 80e6 - correlator clock frequency;
#define D_FREQ 0x346D           //Doppler search step (1000Hz): (1000*2^30)/80e6;

static unsigned short astat;

/* GLOBAL VARIABLE! IT IS USED IN MAIN.C DURING INITIALIZATIONè! */
struct tracking_channel chan[N_CHANNELS]; // array of structures that describe each correlator channel;

/* Next two variables should be unites in a structure. Each structure should be assigned to one channel. May be tracking_channel structure should be used? */
#define ACQ_THRESH 1600 //acquisition threshold (set empirically);
#define SEARCH_MAX_F 5  //Half of Doppler search range (in doppler step units: 2*5*1000 = 10000Hz);

//test vectors for debugging:
long test_vectors_length;
long test_vector_01[1000];
long test_vector_02[1000];
long test_vector_03[1000];
long test_vector_04[1000];
long test_vector_05[1000];
long test_vector_06[1000];

#define CONFIRM_M      3   // Acquisition confirmation steps number;
#define N_OF_M_THRESH  2   // Required number of confirmations to move to pull-in process;

#define sign(x) (x > 0 ? 1 : (x == 0) ? 0 : -1) //function sign(x)

/* bit-manipulation functions */
#define  test_bit(bit_n, data) ((*((unsigned short *)(data))) &   (0x1 << (bit_n)))
#define   set_bit(bit_n, data) ((*((unsigned short *)(data))) |=  (0x1 << (bit_n)))
#define clear_bit(bit_n, data) ((*((unsigned short *)(data))) &= ~(0x1 << (bit_n)))

static void ch_acq (int);
static void ch_confirm (int);
static void ch_pull_in (int);

/******************************************************************************
FUNCTION output_tst_data()
RETURNS  None.

PARAMETERS None.

PURPOSE
           Output test data!.

WRITTEN BY
        Clifford Kelley. Updated by Gavrilov Artyom.

******************************************************************************/
static void
output_test_data ()
{
  int i;

  for(i=0; i<test_vectors_length; i++)
   mprintf("%d\t%d\t%d\t%d\t%d\t%d\n", test_vector_01[i], test_vector_02[i],
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

static long
rss (long a, long b)
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

static long
fix_sqrt (long x)
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
        This function finds the fixed point square root of a long integer.

WRITTEN BY
        Íèêîëàé Ãàðáóç
        e-mail: nick@sf.demos.su
        http://algolist.manual.ru/maths/count_fast/intsqrt.php

******************************************************************************/
unsigned sqrt_newton(long L)
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


static long
fix_atan2 (long y, long x)
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
void
gpsisr (void)
{
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
static void
ch_acq (int ch)
{
  long prompt_mag;
  struct tracking_channel *c = &chan[ch];

  if (abs (c->n_freq) <= SEARCH_MAX_F) { //search frequencies;
    prompt_mag = rss (c->accum.i_prompt, c->accum.q_prompt); //calculate prompt-magnitude;
    if (prompt_mag > ACQ_THRESH) {
      c->state = CHANNEL_CONFIRM; //start confirmation process;
      c->i_confirm = 0;
      c->n_thresh  = 0;
    }
    else {
      ch_code_slew(ch, 1); //make half chip delay.
      c->codes += 1;
    }
    if (c->codes == 2044) {//all delays are passed for this Doppler bin so move to next one.
      c->n_freq += c->del_freq;
      c->del_freq = -(c->del_freq + sign (c->del_freq));
      c->carrier_freq = CARRIER_REF + c->carrier_cold_corr + D_FREQ * c->n_freq;
      ch_carrier (ch, c->carrier_freq);
      c->codes = 0;
    }
  }
  else {
    mprintf("RESET ACQUISITION\n\n\n"); //Start acquisition from the begining.
    c->n_freq   = 0;
    c->del_freq = 1;
    c->carrier_freq = CARRIER_REF + c->carrier_cold_corr;
    ch_carrier (ch, c->carrier_freq);
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
static void
ch_confirm (int ch)
{
  long prompt_mag;
  struct tracking_channel *c = &chan[ch];

  prompt_mag = rss (c->accum.i_prompt, c->accum.q_prompt); //calculate prompt-magnitude;

  if (prompt_mag > ACQ_THRESH)
    c->n_thresh++;
  if (c->i_confirm == CONFIRM_M) {
    if (c->n_thresh >= N_OF_M_THRESH) {
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
static void
ch_pull_in (int ch)
{
  long early_mag, late_mag;

  struct tracking_channel *c = &chan[ch];
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
  ch_code(ch, c->codeFreq);


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
  ch_carrier(ch, c->carrFreq);


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
  if ( (c->ch_time < 1000) ) {
    test_vectors_length++;
    test_vector_01[c->ch_time] = c->accum.i_early;
    test_vector_02[c->ch_time] = c->accum.q_early;
    test_vector_03[c->ch_time] = c->accum.i_prompt;
    test_vector_04[c->ch_time] = c->accum.q_prompt;
    test_vector_05[c->ch_time] = c->accum.i_late;
    test_vector_06[c->ch_time] = c->accum.q_late;
  }

  /*if ( (c->ch_time < 1200)&&(c->ch_time > 200) ) {
    test_vector_01[test_vectors_length] = c->accum.i_early;
    test_vector_02[test_vectors_length] = c->accum.q_early;
    test_vector_03[test_vectors_length] = c->accum.i_prompt;
    test_vector_04[test_vectors_length] = c->accum.q_prompt;
    test_vector_05[test_vectors_length] = c->accum.i_late;
    test_vector_06[test_vectors_length] = c->accum.q_late;
    test_vectors_length++;
  }*/

  c->ch_time++;

  if ( (c->sign_count > 30) ) { // pull-in condition. Here we count how many times bits lasted more then 19 ms. This method seems bad but it works.
    mprintf("YESSSSSSS!!!!!!!!!!\n\n\n\n");
    output_test_data(); //Output debug data through RS-232.
    c->state = CHANNEL_BIT_SYNC;
    mprintf("YESSSSSSS!!!!!!!!!!\n\n\n\n");
  }

  if (c->ch_time == 3000) {    // Pull-in process lasts not more then 3 seconds. If 3 seconds passed and lock is not achieved then acquisition process starts from the beginnig.
    mprintf("Acquisition failed!!!\n\n");
    output_test_data(); //Output debug data through RS-232.
    c->state = CHANNEL_ACQUISITION;
  }

}



