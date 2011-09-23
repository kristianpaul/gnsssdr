#ifndef ISR_H_
#define ISR_H_

struct accum {          // Стурктура, хранящая все 6 выходов коррелятора (значения 6-ти сумматоров);
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
  TRACKING_ENUM       state;                    // Состояние канала;
  struct accum        accum, prev_accum, prev2_accum; // Выходы с 6-ти корреляторов;
  struct accum_mag    accum_mean;               // Усреднение 6-ти корреляторов во время подтверждения;

  long                cross, dot;               // cross и dot - переменные расчитываемые по значениям accum и accum_prev;
  long                carrError, oldCarrError;  // Выход фазового дискриминатора;
  long                freqError;                // Выход частотного дискриминатора;
  long                carrNco, oldCarrNco;      // Текущая поправка к частоте генератора несущей, полученной в процедуре поиска. И предыдущее значение поправки.
  long                carrFreq, carrFreqBasis;  // Текущая частота генератора несущей и опорное значение частоты генератора несущей, полученное в процедуре обнаружения сигнала;

  long                codeError, oldCodeError;  // Выход дискриминатора задержки и его предыдущее значение;
  long                codeFreq, codeFreqBasis;  // Текущая частота тактового генератора ПСП и опорное тактовой частоты генератора ПСП;
  long                codeNco, oldCodeNco;      // Текущая поправка к тактовой частоте генератора ПСП, относительно номинального значения. И предыдущее значение поправки.

  long                ch_time;                  //

  int                 n_freq;                   // Номер текущей ячейки поиска по частоте;
  int                 i_confirm;                // для поиска; Текущий номер итерции процедуры подтверждения;
  int                 n_thresh;                 // для поиска; Сколько раз был превышен порог в процедуре подтверждения;
  int                 codes;                    // Сколько получипов уже перебрано в текущей ячейке по частоте Доплера.
                                                // Используется в процедуре поиска определения момента перехода к следующей ячейке поиска по частоте Доплера.
  int                 del_freq;                 // Вспомогательная переменная, использующаяся при расчете номера текущей ячейки поиска по частоте;
  char                CN0;                      // Current carrier to noise ratio;
  long                carrier_freq;             // Carrier frequency for this channel;
  long                carrier_cold_corr;        // Поправка к carrier_ref для условно холодного поиска, когда есть информация о текущей частоте доплера спутника.

  int                 sign_pos, prev_sign_pos;  // Предполагаемые границы битов: текущая и предыдущая.
  int                 sign_count;               // Сколько раз предполагаемая граница битов длилась больше 19 мс!
};


extern void gpsisr (void);



#endif /* ISR_H_ */
