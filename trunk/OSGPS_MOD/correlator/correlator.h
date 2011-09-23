/*****************************************************************************
 *   correlator.h:  Header file for external correlator
 *
 *   Copyright(C) 2011, Artyom Gavrilov
  *
 *   History
 *   2011.06.28  ver 0.01    Prelimnary version, first Release
 *
******************************************************************************/
#ifndef __CORRELATOR_H
#define __CORRELATOR_H

/*****************************************************************************
 * Defines and typedefs
 ****************************************************************************/

#define CORR_BASE_ADDR  0x80000000

#define CORR_ch0_prn_key         (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x00))
#define CORR_ch0_i_early         (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x02))
#define CORR_ch0_q_early         (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x04))
#define CORR_ch0_i_prompt        (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x06))
#define CORR_ch0_q_prompt        (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x08))
#define CORR_ch0_i_late          (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x0A))
#define CORR_ch0_q_late          (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x0C))
//#define CORR_epoch               (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x0E))
//#define CORR_epoch_check         (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x10))
//#define CORR_epoch_load          (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x12))
#define CORR_ch0_code_slew       (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x14))
#define CORR_ch0_code_nco_low    (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x16))
#define CORR_ch0_code_nco_high   (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x18))
#define CORR_ch0_carr_nco_low    (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x1A))
#define CORR_ch0_carr_nco_high   (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x1C))
//#define CORR_ch0_code_val_low    (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x1E))
//#define CORR_ch0_code_val_high   (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x20))
//#define CORR_ch0_carr_val_low    (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x22))
//#define CORR_ch0_carr_val_high   (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x24))

#define CORR_status              (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x1E0))
#define CORR_clean_status        (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x1E2))
#define CORR_new_data            (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x1E4))
#define CORR_clean_new_data      (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x1E6))
#define CORR_tic_cnt_low         (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x1E8))
#define CORR_tic_cnt_high        (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x1EA))
#define CORR_acum_cnt_low        (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x1EC))
#define CORR_acum_cnt_high       (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x1EE))

#define CORR_reset               (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x1F0))
#define CORR_TIC_div_low         (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x1F2))
#define CORR_TIC_div_high        (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x1F4))
#define CORR_accum_int_div_low   (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x1F6))
#define CORR_accum_int_div_high  (*(volatile unsigned short *)(CORR_BASE_ADDR + 0x1F8))

extern int  memory_test (void);
extern void correlator_init(void);

#endif /* end __CORRELATOR_H */
/*****************************************************************************
**                            End Of File
******************************************************************************/
