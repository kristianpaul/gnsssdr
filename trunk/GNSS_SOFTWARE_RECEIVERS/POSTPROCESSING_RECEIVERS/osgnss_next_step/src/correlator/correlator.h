#ifndef CORRELATOR_H_
#define CORRELATOR_H_

int REG_read[256], REG_write[256];// This global variable is not included in global.h
                                  // because it is software-correlator specific!

extern void write_to_file_prn_codes(int prnn);
extern void correlator_init (double tic_period);
extern void Sim_GP2021_int (char *IF, long nsamp);

#endif /* CORRELATOR_H_ */
