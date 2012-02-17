/*
 *  This is the primary data structure that provides access
 *  to the components of each channel
 */
#ifndef STRUCTS_H
#define STRUCTS_H

struct almanac                  /* Approximate orbital parameters */
{
  float w, ety, inc, rra, sqa, lan, aop, ma, toa, af0, af1;
  char text_message[23];
  int health, week, sat_file;
};
typedef struct almanac almanac;

struct ephemeris                /* Precise orbital parameters */
{
  int iode, iodc, ura, valid, health, week;
  double dn, tgd, toe, toc, omegadot, idot, cuc, cus, crc, crs, cic, cis;
  double ma, e, sqra, w0, inc0, w, wm, ety, af0, af1, af2;
};
typedef struct ephemeris ephemeris;

struct ecef
{
  double x, y, z;
};
typedef struct ecef ecef;

struct eceft
{
  double x, y, z, tb;
  float az, el;
};
typedef struct eceft eceft;

struct llh
{
  double lat, lon, hae;
};
typedef struct llh llh;

struct pvt
{
  double x, y, z, dt;
  double xv, yv, zv, df;
};
typedef struct pvt pvt;

/*============================================================================================================*/
/* Structs for satellite signals tracking rootines: */

/* Structure keeps values from 6 correlators (values of 6 integrators): */
struct accum {
  short i_prompt;
  short q_prompt;
  short i_late;
  short q_late;
  short i_early;
  short q_early;
};
typedef struct accum accum;

/* Structure keeps values of energies in each channel: early, prompt, late: */
struct accum_mag {
  long early_mag;
  long prompt_mag;
  long late_mag;
};
typedef struct accum_mag accum_mag;

typedef enum {
    CHANNEL_OFF         = 0,
    CHANNEL_ACQUISITION = 1,
    CHANNEL_CONFIRM     = 2,
    CHANNEL_PULL_IN     = 3,
    CHANNEL_TRACKING    = 4
} tracking_enum;

typedef enum {
    CHANNEL_GPS         = 0,
    CHANNEL_GLONASS     = 1
} channel_gnss_system_enum;

/* Structure describes one channel */
struct tracking_channel
{
  channel_gnss_system_enum system;              // Channel GNSS system (GPS/GLONASS). For future use!
  tracking_enum state;                          // Channel state;
  accum         accum, prev_accum;              // 6 correlators outputs;
  accum_mag     accum_mean;                     // Avarage of 6 correlators during confirmation;

  long          cross, dot;                     // cross и dot - variables calculated from "accum" and "accum_prev";
  long          carrError, oldCarrError;        // phase discriminator output;
  long          freqError;                      // frequency discriminator output;
  long          carrNco, oldCarrNco;            // Current correction to frequency of carrier-NCO, obtained during acquisition. And it's previous value.
  long          carrFreq, carrFreqBasis;        // Current frequency of carrier-NCO and frequency-base-value obtained during acquisition;

  long          codeError, oldCodeError;        // Delay discriminator output and it's previous value;
  long          codeFreq, codeFreqBasis;        // Current clock frequency of PRN-generator and clock-base-value of PRN-generator;
  long          codeNco, oldCodeNco;            // Current correction to clock frequency of PRN-generator, comparing to nominal value. And it's previous value;

  long          ch_time;                        //

  int           n_freq;                         // Current Doppler bin number;
  int           i_confirm;                      // for confirmation; Current number of confirmation step;
  int           n_thresh;                       // for confirmation; How many times threshold was overcomed during confirmation;
  int           codes;                          // How many half-chip is checked for current Doppler-bin.
                                                // It is used during acquisition in order to determine when to move to next Doppler-bin.
  int           del_freq;                       // Auxiliary variable, it is used in calculation of the Doppler-bin in which signal will be searched;
  char          CN0;                            // Current carrier to noise ratio;
  long          carrier_freq;                   // Carrier frequency for this channel;
  long          carrier_cold_corr;              // Correction to carrier_ref for quasi-cold-search when there is information about Doppler of the satellite to to be searched.

  int           sign_pos, prev_sign_pos;        // Expected bits edges: current and previous.
  int           sign_count;                     // How many times expected bit lasted more then 19 ms!

  int           search_max_PRN_delay;           // PRN_delay search range in half-chips (2045 half chip for GPS, 1021 for GLONASS).
  int           search_max_f;                   // Doppler search range in kHz.
  int           coherent_integration_time;      // Coherent integration time. In the simplest case = 1 [ms]. For future use!
};
typedef struct tracking_channel tracking_channel;

#endif
