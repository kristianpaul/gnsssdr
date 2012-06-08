struct accum {          // Structure that keeps correlator outputs for 1 channel;
  short i_prompt;
  short q_prompt;
  short i_late;
  short q_late;
  short i_early;
  short q_early;
};

struct accum_mag {
  long early_mag;
  long prompt_mag;
  long late_mag;
};

typedef enum {
    CHANNEL_OFF         = 0,
    CHANNEL_ON          = 1,
    CHANNEL_ACQUISITION = 1,
    CHANNEL_CONFIRM     = 2,
    CHANNEL_PULL_IN     = 3,
    CHANNEL_BIT_SYNC    = 4,
    CHANNEL_LOCK        = 5
} TRACKING_ENUM;

struct tracking_channel
{
  TRACKING_ENUM       state;                    // Channel state;
  struct accum        accum, prev_accum, prev2_accum; // Outputs from 6 correlators of 1 channel.
  struct accum_mag    accum_mean;               // Mean value for each of 6 correlators during acquisition confirmation;

  long                cross, dot;               // cross and dot - values are calculated with accum and accum_prev;
  long                carrError, oldCarrError;  // Phase discriminator output;
  long                freqError;                // Frequency discriminator output;
  long                carrNco, oldCarrNco;      // Current correction of local_carrier_frequency and it's previous value.
  long                carrFreq, carrFreqBasis;  // Current value of local_carrier_generator frequency 
						//and nominal value after acquisition;

  long                codeError, oldCodeError;  // Delay discriminator output and it's previous value;
  long                codeFreq, codeFreqBasis;  // Current value of clock of PRN-generator and it's nominal value;
  long                codeNco, oldCodeNco;      // Current correction of PRN-generator clock and it's previous value.

  long                ch_time;                  //

  int                 n_freq;                   // Current number of search frequency bin;
  int                 i_confirm;                // for acquisition; Current confirmation step number.
  int                 n_thresh;                 // for acquisition; How many times threshold was archieved;
  int                 codes;                    // How many half chips is checked for current frequency bin.
                                                // Used during acquisition in order to determine the time 
						//of switch to next doppler bin.
  int                 del_freq;                 // Auxilliary variable used to calculate current Doppler bin number;
  char                CN0;                      // Current carrier to noise ratio;
  long                carrier_freq;             // Carrier frequency for this channel;
  long                carrier_cold_corr;        // Correction to carrier_ref for pseudocold search when 
						//current Doppler is known.

  int                 sign_pos, prev_sign_pos;  // Expected bits edges: current and previous.
  int                 sign_count;               // How many times bit edges distance is more then 19 ms!
};
