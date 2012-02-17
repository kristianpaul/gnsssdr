#include <string.h> // for memset().
#include <math.h>   // for pow().
#include <stdint.h>
#include "correlator.h"
#include ".\..\include\globals.h"

// Names definitions like in GP2021 datasheet:
//REG_write
#define SATCNTL               0
#define CARRIER_DCO_INCR_HIGH 3
#define CARRIER_DCO_INCR_LOW  4
#define CODE_DCO_INCR_HIGH    5
#define CODE_DCO_INCR_LOW     6
//REG_read
#define I_EARLY  4
#define Q_EARLY  5
#define I_PROMPT 2
#define Q_PROMPT 3
#define I_LATE   0
#define Q_LATE   1

#define sign(x) (x > 0 ? 1 : (x == 0) ? 0 : -1) // sign(x) function definition.

// Three arrays contain PRN-codes for GPS satellites:
static char gps_prn_early[33][2046],    //early PRN codes;
            gps_prn_prompt[33][2046],   //prompt PRN codes;
            gps_prn_late[33][2046];     //late PRN codes.

// Variables to generate TIC. Look in GP2021 datasheet for details:
static long tic_ref, tic=0;

// Internal correlator variables:
static int   ms_counter[N_CHANNELS], bit_counter[N_CHANNELS];

// Structure describes correlator's channels state:
struct gp2021_channel {
  uint32_t int_carrier_phase;
  uint32_t int_carrier_cycle;
  uint32_t int_code_phase;
  uint16_t int_code_half_chip;
  int32_t  i_prompt_accum;              // 6 accumulators;
  int32_t  q_prompt_accum;
  int32_t  i_late_accum;
  int32_t  q_late_accum;
  int32_t  i_early_accum;
  int32_t  q_early_accum;
} gpchan[N_CHANNELS];

/******************************************************************************
FUNCTION generate_prn_codes(void)
RETURNS  None.

PARAMETERS None.

PURPOSE
        This function generates PRN-codes. Three arrays are generated: early, prompt and late.

WRITTEN BY
        Artyom Gavrilov. Based on Clifford Kelley source.

******************************************************************************/

static void
generate_gps_prn_codes(void)
{
  int i, j, G1, G2, prn, chip, half_chip;
  int G2_i[33] = {
    0x000, 0x3f6, 0x3ec, 0x3d8, 0x3b0, 0x04b, 0x096, 0x2cb, 0x196,
    0x32c, 0x3ba, 0x374, 0x1d0, 0x3a0, 0x340, 0x280, 0x100,
    0x113, 0x226, 0x04c, 0x098, 0x130, 0x260, 0x267, 0x338,
    0x270, 0x0e0, 0x1c0, 0x380, 0x22b, 0x056, 0x0ac, 0x158};

  for (prn=1; prn<33; prn++) {  //pass through all satellites.
    char prn_code[1023];        //this array contains GOLD-code for current satellite.
    prn_code[0]=1;
    G1 = 0x1FF;
    G2 = G2_i[prn];
    for (chip=1; chip<1023; chip++) { //GPS C/A PRN length is 1023.
      prn_code[chip]=(G1^G2) & 0x1;   // exor the right hand most bit.
      i  = ((G1<<2)^(G1<<9)) & 0x200;
      G1 = (G1>>1) | i;
      j  = ((G2<<1)^(G2<<2)^(G2<<5)^(G2<<7)^(G2<<8)^(G2<<9)) & 0x200;
      G2 = (G2>>1) | j;
    }
    for (half_chip=0; half_chip<2046; half_chip++) {
      gps_prn_early[prn][half_chip]  = 2*prn_code[((half_chip+0)%2046)>>1] - 1;
      gps_prn_prompt[prn][half_chip] = 2*prn_code[((half_chip+1)%2046)>>1] - 1;
      gps_prn_late[prn][half_chip]   = 2*prn_code[((half_chip+2)%2046)>>1] - 1;
    }
  }
}

/******************************************************************************
FUNCTION correlator_init(void)
RETURNS  None.

PARAMETERS None.

PURPOSE
        This function initializes correlator.

WRITTEN BY
        Clifford Kelley.

******************************************************************************/

void
correlator_init (double tic_period)
{
  Carrier_DCO_Delta = SYSTEM_CLOCK_MULTIPLIER*SAMP_RATE / pow(2.0, CARRIER_NCO_DIGIT_CAPACITY);  // carrier frequency resolution (carrier NCO resolution).
  Code_DCO_Delta    = SYSTEM_CLOCK_MULTIPLIER*SAMP_RATE / pow(2.0, CODE_NCO_DIGIT_CAPACITY);  // PRN clock frequency resolution (code clock NCO resolution);

  // Carrier and code reference frequencies for GPS signals:
  gps_code_ref    = GPS_CODE_F  / Code_DCO_Delta;       // nominal value of code clock NCO control-word. For GPS signals.
  gps_carrier_ref = GPS_CARRIER_IF / Carrier_DCO_Delta; // nominal value of carrier NCO control-word. For GPS signals.
  // Carrier and code reference frequencies for GLONASS signals:
  glonass_code_ref    = GLONASS_CODE_F  / Code_DCO_Delta;       // nominal value of code clock NCO control-word. For GLONASS signals.
  glonass_carrier_ref = GLONASS_CARRIER_IF / Carrier_DCO_Delta; // nominal value of carrier NCO control-word. For GLONASS signals.

  // Acquisition Doppler bin size (NCO control-word value):
  d_freq = (int) freq_bin_width / Carrier_DCO_Delta;

  // osgps native code:
  tic_ref = SAMP_RATE * tic_period;
  tic = tic_ref;

  // Fill with zeros array of structures of gp2021_channel type;
  memset(gpchan, 0, sizeof(struct gp2021_channel) * N_CHANNELS);

  // generate PRNs for eacg SVN and fill with them arrays prn_early[33][2046], prn_prompt[33][2046], prn_late[33][2046];
  generate_gps_prn_codes();
}

/******************************************************************************
FUNCTION Sim_GP2021_int (char *IF, long nsamp)
RETURNS  None.

PARAMETERS Signal samples, number of samples per interrupt.

PURPOSE
        This function emulates gp2021 correlator.

WRITTEN BY
        Artyom Gavrilov. Based on Clifford Kelley source.

******************************************************************************/

void
Sim_GP2021_int (char *IF, long nsamp)
{
  int ch;
  int Accum_status_A, tic_count;


  if (tic < nsamp) { // will a tic occur during this sample set?
    // yes, tic count is sample number where tic occurs:
    tic_count = tic;

    // reset tic for next time:
    tic += tic_ref - nsamp;
  }
  else {
    tic-=nsamp;   // no, reduce tic by nsamples.
    tic_count=-1; // -1 means no tic occurs in this sample set.
  }


  Accum_status_A = 0;

  for (ch=0; ch < N_CHANNELS; ch++) {
    int reg = ch<<3;
    int slew_dump = REG_write[(ch<<3)+0x84]+2046; // Some kind of trick is used here?! Which leads to the fact that sometimes during access to
                                                  // arrays gps_prn_*[prn] out-of-bound access (of current prn) happens?!
                                                  // May be that is why 34 PRNs aure used though there are only 32 SVNs...

    // implement epoch set:
    if (REG_write[reg+7] != -1) {
      REG_read[reg+7] = REG_write[reg+7];
      ms_counter[ch]=REG_write[reg+7] & 0xff;    // set ms counter;    low  byte - ms_counter.
      bit_counter[ch]=REG_write[reg+7]>>8;       // set bit counter;   high byte - bit_counter.
      REG_write[reg+7]=-1;                       // reset epoch set.
    }

    // Don't bother continuing if this channel is idle i.e. no PRN assigned:
    if (REG_write[reg] > 0) {
      // reading control word of carrier NCO.
      uint32_t carrier_dco_incr = (REG_write[reg + CARRIER_DCO_INCR_HIGH]<<16) + REG_write[reg + CARRIER_DCO_INCR_LOW];
      // reading control word of PRN-clock-NCO.
      uint32_t code_dco_incr    = (REG_write[reg + CODE_DCO_INCR_HIGH]<<16)    + REG_write[reg + CODE_DCO_INCR_LOW];
      // global variable ichan is not used any more in the next 3 lines:
      char *this_prn_prompt = gps_prn_prompt[REG_write[reg]];
      char *this_prn_late   = gps_prn_late[REG_write[reg]];
      char *this_prn_early  = gps_prn_early[REG_write[reg]];
      struct gp2021_channel *this_gpchan = &gpchan[ch];
      char *ifptr = IF;
      int prompt_ca_bit = this_prn_prompt[this_gpchan->int_code_half_chip];
      int late_ca_bit   = this_prn_late[this_gpchan->int_code_half_chip];
      int early_ca_bit  = this_prn_early[this_gpchan->int_code_half_chip];
      int i;

      for (i=0; i<nsamp; i++) {  // correlate each data sample:
        // We use "int" type here instead of "char" ONLY because it's faster:
        static const int i_lo_seq[8] = {-1, 1, 2, 2, 1,-1,-2,-2};
        static const int q_lo_seq[8] = { 2, 2, 1,-1,-2,-2,-1, 1};

        int idx = this_gpchan->int_carrier_phase >> 29;
        int ival;
        int qval;
        if (use_iq_processing) { // if IQ-processing is used:
          int tif_i = *ifptr++;
          int tif_q = *ifptr++;

          // First (carrier) mixer (in case of IQ-processing multiplication of complex numbers is realized here):
          qval = (q_lo_seq[idx] * tif_i) - (i_lo_seq[idx] * tif_q);
          ival = (i_lo_seq[idx] * tif_i) + (q_lo_seq[idx] * tif_q);
        }
        else {                   // if only I-processing is used:
          int tif = *ifptr++;
          ///int tif = (*ifptr++) >> 1; //1-bit quantization emulation! Used only for 2bit input data!!!

          // First (carrier) mixer (in case of only I-processing simple multiplication is realized here):
          ival = tif * i_lo_seq[idx];
          qval = tif * q_lo_seq[idx];
        }

        // Second (code) mixer:
        this_gpchan->q_late_accum   += late_ca_bit   * qval;
        this_gpchan->q_prompt_accum += prompt_ca_bit * qval;
        this_gpchan->q_early_accum  += early_ca_bit  * qval;
        this_gpchan->i_late_accum   += late_ca_bit   * ival;
        this_gpchan->i_prompt_accum += prompt_ca_bit * ival;
        this_gpchan->i_early_accum  += early_ca_bit  * ival;

        // This is designed to wrap carrier around at 32-bits:
        {
            uint32_t carrier_rollover = this_gpchan->int_carrier_phase;
            this_gpchan->int_carrier_phase += carrier_dco_incr;
            if (this_gpchan->int_carrier_phase < carrier_rollover)
              this_gpchan->int_carrier_cycle++;
        }

        // This is designed to wrap code around at 32-bits:
        {
            uint32_t code_rollover =  this_gpchan->int_code_phase;
            this_gpchan->int_code_phase  += (code_dco_incr << 1); // It's not clear for me: why code_dco_incr is multipling by 2?..
            if (this_gpchan->int_code_phase < code_rollover) {
              this_gpchan->int_code_half_chip++;
              prompt_ca_bit = this_prn_prompt[this_gpchan->int_code_half_chip];
              late_ca_bit   = this_prn_late[this_gpchan->int_code_half_chip];
              early_ca_bit  = this_prn_early[this_gpchan->int_code_half_chip];
              if  (this_gpchan->int_code_half_chip>=slew_dump) { // dump
                // dump correlators into the appropriate 2021 registers
                // scale down to match 2021 statistics:
                reg=(ch<<3)+0x84;
                REG_read[reg + I_LATE]   = this_gpchan->i_late_accum;
                REG_read[reg + Q_LATE]   = this_gpchan->q_late_accum;
                REG_read[reg + I_PROMPT] = this_gpchan->i_prompt_accum;
                REG_read[reg + Q_PROMPT] = this_gpchan->q_prompt_accum;
                REG_read[reg + I_EARLY]  = this_gpchan->i_early_accum;
                REG_read[reg + Q_EARLY]  = this_gpchan->q_early_accum;

                // reset slew to 0:
                REG_write[reg] = 0;

                // reset the correlators:
                this_gpchan->i_late_accum   =  this_gpchan->q_late_accum   =
                this_gpchan->i_prompt_accum =  this_gpchan->q_prompt_accum =
                this_gpchan->i_early_accum  =  this_gpchan->q_early_accum  = 0;
                this_gpchan->int_code_half_chip = 0;

                // set the bit if a dump occurs:
                Accum_status_A = Accum_status_A | (1<<ch);

                // increment ms and bit counters:
                ms_counter[ch] ++;      // ms counter;
                if (ms_counter[ch]==20)
                  // bit counter:
                  bit_counter[ch] = (++bit_counter[ch])%50;
                ms_counter[ch] = ms_counter[ch] % 20;
                REG_read[ch*8+7] = ms_counter[ch] + (bit_counter[ch]<<8);
              }
            }
        }

        // at TIC save the carrier and code info for measurements:
        if (i==tic_count) {
          reg=ch<<3;

          // ms and bit counters:
          REG_read[reg+4] = REG_read[reg+7];
          // carrier phase (top 10 bits):
          REG_read[reg+3] = this_gpchan->int_carrier_phase >> 22;
          // number of half chips:
          REG_read[reg+1] = this_gpchan->int_code_half_chip;
          // half chip phase (top 10 bits):
          REG_read[reg+5] = this_gpchan->int_code_phase >> 22;
          // carrier cycle low:
          REG_read[reg+2] = this_gpchan->int_carrier_cycle & 0xffff;
          // carrier cycle high:
          REG_read[reg+6] = this_gpchan->int_carrier_cycle >> 16;

          this_gpchan->int_carrier_cycle=0;
        }
      }
    }
  }

  // load the register for accum status A bits:
  REG_read[0x82]=Accum_status_A;

  // if a tic occurs set the accum status B bit:
  if (tic_count > -1)
    REG_read[0x83]=0x2000;
  else
    REG_read[0x83]=0x0;
}
