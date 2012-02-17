#ifndef GP2021_H_
#define GP2021_H_

extern int REG_read[256], REG_write[256];// This global variable is not included in global.h
                                         // because it is software-correlator specific!

extern int accum_status (void);
extern int ch_i_prompt (int);
extern int ch_q_prompt (int);
extern int ch_i_late (int);
extern int ch_q_late (int);
extern int ch_i_early (int);
extern int ch_q_early (int);
extern void ch_code_slew (int, int);
extern void ch_carrier (int, long);
extern void ch_code (int, long);
extern void ch_cntl (int, int);

#endif /* GP2021_H_ */
