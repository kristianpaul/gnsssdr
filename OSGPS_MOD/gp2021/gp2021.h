#ifndef GP2021_H_
#define GP2021_H_

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
extern void program_TIC (long);
extern void program_accum_int (long data);
extern void full_reset (void);
extern long get_status (void);
extern void clear_status (void);

#endif /* GP2021_H_ */
