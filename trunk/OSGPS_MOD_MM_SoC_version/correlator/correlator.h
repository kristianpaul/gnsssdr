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

#define CORR_BASE_ADDR  0x20000000

#define CORR_WRITE_MEMORY_BASE (CORR_BASE_ADDR + 4*0x20)
#define CORR_READ_MEMORY_BASE  (CORR_BASE_ADDR + 4*0x40)


#define CORR_ch0_prn_key         (*(volatile unsigned int *)(CORR_BASE_ADDR + 4*0x00))
#define CORR_ch0_carr_nco        (*(volatile unsigned int *)(CORR_BASE_ADDR + 4*0x01))
#define CORR_ch0_code_nco        (*(volatile unsigned int *)(CORR_BASE_ADDR + 4*0x02))
#define CORR_ch0_code_slew       (*(volatile unsigned int *)(CORR_BASE_ADDR + 4*0x03))
#define CORR_ch0_i_early         (short int)(*(volatile unsigned int *)(CORR_BASE_ADDR + 4*0x04))
#define CORR_ch0_q_early         (short int)(*(volatile unsigned int *)(CORR_BASE_ADDR + 4*0x05))
#define CORR_ch0_i_prompt        (short int)(*(volatile unsigned int *)(CORR_BASE_ADDR + 4*0x06))
#define CORR_ch0_q_prompt        (short int)(*(volatile unsigned int *)(CORR_BASE_ADDR + 4*0x07))
#define CORR_ch0_i_late          (short int)(*(volatile unsigned int *)(CORR_BASE_ADDR + 4*0x08))
#define CORR_ch0_q_late          (short int)(*(volatile unsigned int *)(CORR_BASE_ADDR + 4*0x09))

//#define CORR_epoch               (*(volatile unsigned int *)(CORR_BASE_ADDR + 0x))
//#define CORR_epoch_check         (*(volatile unsigned int *)(CORR_BASE_ADDR + 0x))
//#define CORR_epoch_load          (*(volatile unsigned int *)(CORR_BASE_ADDR + 0x))

//#define CORR_ch0_code_val        (*(volatile unsigned int *)(CORR_BASE_ADDR + 0x))
//#define CORR_ch0_carr_val        (*(volatile unsigned int *)(CORR_BASE_ADDR + 0x))

#define CORR_status              (*(volatile unsigned int *)(CORR_BASE_ADDR + 4*0xE0))
#define CORR_clean_status        (*(volatile unsigned int *)(CORR_BASE_ADDR + 4*0xE1))
#define CORR_new_data            (*(volatile unsigned int *)(CORR_BASE_ADDR + 4*0xE2))
#define CORR_clean_new_data      (*(volatile unsigned int *)(CORR_BASE_ADDR + 4*0xE3))

//#define CORR_tic_cnt             (*(volatile unsigned int *)(CORR_BASE_ADDR + 0x))
//#define CORR_acum_cnt            (*(volatile unsigned int *)(CORR_BASE_ADDR + 0x))

#define CORR_reset               (*(volatile unsigned int *)(CORR_BASE_ADDR + 4*0xF0))
#define CORR_TIC_div             (*(volatile unsigned int *)(CORR_BASE_ADDR + 4*0xF1))
#define CORR_accum_int_div       (*(volatile unsigned int *)(CORR_BASE_ADDR + 4*0xF2))

extern int  memory_test (void);
extern void correlator_init(void);

#endif /* end __CORRELATOR_H */
/*****************************************************************************
**                            End Of File
******************************************************************************/
