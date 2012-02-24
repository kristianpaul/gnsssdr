#ifndef GLOBALS_H
#define GLOBALS_H

#include <stdio.h>
#include "structs.h"

#define N_CHANNELS    12 /* Number of correlator channels.                                            */
#define CONFIRM_M     3  /* Number of step during confirmation process.                               */
#define N_OF_M_THRESH 2  /* Required number of successful confirmations in confirmation process.      */

/* parameters for GNSS-SDR front-end */
#define SAMP_RATE  (float)16.0000e6      /* sampling rate.                                            */
#define SYSTEM_CLOCK_MULTIPLIER (float)3 /* this constant shows the relation between sampling
                                            frequency and system clock frequency. This is
                                            used to simulate HADWARE RECEIVERS! FOR
                                            PURE SOFTWARE RECEIVER IT SHOULD BE 1.                    */
#define GPS_CARRIER_IF (float)2.4200e6   /* carrier Intermediate Frequency for GPS signals            */
#define GPS_CODE_F 1023000               /* PRN generator nominal clock frequency for GPS signals     */
#define GLONASS_CARRIER_IF (float)0.0e6  /* carrier Intermediate Frequency for GLONASS signals        */
#define GLONASS_CODE_F 511000            /* PRN generator nominal clock frequency for GLONASS signals */
#define CARRIER_NCO_DIGIT_CAPACITY 30    /* Digit capacity of carrier NCO                             */
#define CODE_NCO_DIGIT_CAPACITY    29    /* Digit capacity of code clock NCO                          */
#define MAX_DIGIT_CAPACITY_OF_ANY_NCO 32 /* Maximum digit capacity of carrier NCO or code clock NCO   */

#define TIC_CODE 0x00493DFF              /* TIC-periode to 0.1 sec                       */ /* write comments!*/
#define ACCUM_INT_CODE 0x00005DBF        /* set ACCUM_INT periode to (0.0005sec = 0.5ms) */ /* write comments!*/

enum
{ cold_start, warm_start, hot_start, tracking, navigating };
/*        0          1          2        3          4     */

#ifdef MAIN

almanac gps_alm[32];     /* almanac data for all GPS satellites. */
ephemeris gps_eph[32];   /* ephemeris data for all GPS satellites. */

pvt rpvt;

tracking_channel chan[N_CHANNELS]; /* Array of structures that describe correlator channels. */

int acq_thresh = 2500;     /* Acquisition threshold. */

/* for Integer GP2021 emulation use 32 bits */
float Carrier_DCO_Delta;   /* frequency resolution for carrier NCO.    */
float Code_DCO_Delta;      /* frequency resolution for code-clock NCO. */

/* Carrier and code reference frequencies */
long gps_code_ref;         /* Nominal value of frequency control word for PRN NCO for GPS signals.         */
long gps_carrier_ref;      /* Nominal value of frequency control word for carrier NCO for GPS signals.     */
long glonass_code_ref;     /* Nominal value of frequency control word for PRN NCO for GLONASS signals.     */
long glonass_carrier_ref;  /* Nominal value of frequency control word for carrier NCO for GLONASS signals. */
long d_freq;               /* Doppler frequency step in acquisition.                   */

int interr_int = 512;      /* interrupt period in us. */
int tic_period = 0.1;      /* TIC period in seconds.  */

float freq_bin_width = 1000; /* Doppler bin width in Hz. */

int use_iq_processing = 1; /* Use IQ-samples processing (1) or only I-samples processing (0). */

/* Tracking loops (DLL and FLL-assisted-PLL loops) parameters. */
long Bnp = 25;             /* Phased locked loop noise bandwidth [Hz].                                                                   */
long Bnf = 1400;           /* Frequency locked loop noise bandwidth [Hz].                                                                */
long Bnd = 2;              /* Delay locked loop noise bandwidth [Hz].                                                                    */
long FLL_a_PLL_integ_time = 1;/* Integration time for FLL-assisted PLL [ms].                                                             */
long DLL_integ_time = 1;      /* Integration time for DLL [ms].                                                                          */
float FLL_a_PLL_k1;       /* FLL-assisted-PLL loop filter first coefficient. Perfect theoretical value for loops with unity gain NCOs.  */
float FLL_a_PLL_k2;       /* FLL-assisted-PLL loop filter second coefficient. Perfect theoretical value for loops with unity gain NCOs. */
float FLL_a_PLL_k3;       /* FLL-assisted-PLL loop filter third coefficient. Perfect theoretical value for loops with unity gain NCOs.  */
float DLL_k1;             /* DLL loop filter first coefficient. Perfect theoretical value for loops with unity gain NCOs.               */
float DLL_k2;             /* DLL loop filter second coefficient. Perfect theoretical value for loops with unity gain NCOs.              */
int FLL_a_PLL_i1;          /* FLL-assisted-PLL loop filter first coefficient. Practical integer value for real NCO.                      */
int FLL_a_PLL_i2;          /* FLL-assisted-PLL loop filter second coefficient. Practical integer value for real NCO.                     */
int FLL_a_PLL_i3;          /* FLL-assisted-PLL loop filter third coefficient. Practical integer value for real NCO.                      */
int DLL_i1;                /* DLL loop filter first coefficient. Practical integer value for real NCO.                                   */
int DLL_i2;                /* DLL loop filter second coefficient. Practical integer value for real NCO.                                  */

/* Array for storing navigation data for maximum 16 channels */
unsigned short data_mesg[1500];    /* Each array element keeps 16-bit data. (1-bit corresponds to 1-channel). */
                                   /* More comments reqired!!! */
unsigned short data_message[1500]; /* Each array element keeps 16-bit data. (1-bit corresponds to 1-channel). */
                                   /* More comments reqired!!! */

int display_page = 0;      /* Current page number to be displayed on screen by display()-function. */
int key;                   /* Current key pressed. Used in display()-function. */

/* FOR DEBUGING: */
//FILE *corr_out;            /* File to write some test data. */

#else

extern almanac gps_alm[33];
extern ephemeris gps_eph[33];

extern pvt rpvt;

extern tracking_channel chan[N_CHANNELS]; /* Array of structures that describe correlator channels. */
extern int acq_thresh;            /* Acquisition threshold. */

extern float Carrier_DCO_Delta;  /* frequency resolution for carrier NCO.    */
extern float Code_DCO_Delta;     /* frequency resolution for code-clock NCO. */

extern long gps_code_ref;         /* Nominal value of frequency control word for PRN NCO.     */
extern long gps_carrier_ref;      /* Nominal value of frequency control word for carrier NCO. */
long glonass_code_ref;     /* Nominal value of frequency control word for PRN NCO for GLONASS signals.     */
long glonass_carrier_ref;  /* Nominal value of frequency control word for carrier NCO for GLONASS signals. */
extern long d_freq;               /* Doppler frequency step in acquisition.                   */

extern int interr_int;            /* interrupt periode in us. */
extern int tic_period;            /* TIC periode in seconds. */

extern float freq_bin_width;     /* Doppler bin width in Hz. */

extern int use_iq_processing;     /* Use IQ-samples processing (1) or only I-samples processing (0). */

extern long Bnp;                  /* Phased locked loop noise bandwidth [Hz].                                                                   */
extern long Bnf;                  /* Frequency locked loop noise bandwidth [Hz].                                                                */
extern long Bnd;                  /* Delay locked loop noise bandwidth [Hz].                                                                    */
extern long FLL_a_PLL_integ_time; /* Integration time for FLL-assisted PLL [ms].                                                                */
extern long DLL_integ_time;       /* Integration time for DLL [ms].                                                                             */
extern float FLL_a_PLL_k1;       /* FLL-assisted-PLL loop filter first coefficient. Perfect theoretical value for loops with unity gain NCOs.  */
extern float FLL_a_PLL_k2;       /* FLL-assisted-PLL loop filter second coefficient. Perfect theoretical value for loops with unity gain NCOs. */
extern float FLL_a_PLL_k3;       /* FLL-assisted-PLL loop filter third coefficient. Perfect theoretical value for loops with unity gain NCOs.  */
extern float DLL_k1;             /* DLL loop filter first coefficient. Perfect theoretical value for loops with unity gain NCOs.               */
extern float DLL_k2;             /* DLL loop filter second coefficient. Perfect theoretical value for loops with unity gain NCOs.              */
extern int FLL_a_PLL_i1;          /* FLL-assisted-PLL loop filter first coefficient. Practical integer value for real NCO.                      */
extern int FLL_a_PLL_i2;          /* FLL-assisted-PLL loop filter second coefficient. Practical integer value for real NCO.                     */
extern int FLL_a_PLL_i3;          /* FLL-assisted-PLL loop filter third coefficient. Practical integer value for real NCO.                      */
extern int DLL_i1;                /* DLL loop filter first coefficient. Practical integer value for real NCO.                                   */
extern int DLL_i2;                /* DLL loop filter second coefficient. Practical integer value for real NCO.                                  */

extern unsigned short data_mesg[1500];    /* Each array element keeps 16-bit data. (1-bit corresponds to 1-channel). */
                                   /* More comments reqired!!! */
extern unsigned short data_message[1500]; /* Each array element keeps 16-bit data. (1-bit corresponds to 1-channel). */
                                   /* More comments reqired!!! */

extern int display_page;          /* Current page number to be displayed on screen by disply()-function. */
extern int key;                   /* Current key pressed. Used in display()-function. */

/* FOR DEBUGING: */
//extern FILE *corr_out;            /* Файл для записи тестовых данных. */

#endif /* MAIN */

#endif /* GLOBALS_H */

