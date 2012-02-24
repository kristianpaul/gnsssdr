#ifndef ISR_H_
#define ISR_H_

extern void gpsisr (void);
extern void calc_FLL_assisted_PLL_filter_loop_coefs(long pll_bw, long fll_bw, long integration_t, float *k1, float *k2, float *k3);
extern void convert_FLL_assisted_PLL_loop_filter_coefs_to_integer(float k1, float k2, float k3, int *i1, int *i2, int *i3);
extern void calc_DLL_loop_filter_coefs(long dll_bw, long integration_t, float *k1, float *k2);
extern void convert_DLL_loop_filter_coefs_to_integer(float k1, float k2, int *i1, int *i2);
extern void test_sqrt(void);

#endif /* ISR_H_ */

