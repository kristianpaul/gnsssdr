#include "./../correlator/correlator.h"

int accum_status (void)
{
	return (CORR_new_data);
}

int ch_i_early (int ch)
{
	return CORR_ch0_i_early;
}

int ch_q_early (int ch)
{
	return CORR_ch0_q_early;
}

int ch_i_prompt (int ch)
{
	return CORR_ch0_i_prompt;
}

int ch_q_prompt (int ch)
{
	return CORR_ch0_q_prompt;
}

int ch_i_late (int ch)
{
	return CORR_ch0_i_late;
}

int ch_q_late (int ch)
{
	return CORR_ch0_q_late;
}

void ch_code_slew (int ch, int data)
{
	CORR_ch0_code_slew = data;	// Not finished! Only one channel for now!
}

void ch_carrier (int ch, long freq)
{
	CORR_ch0_carr_nco = freq;	//Not finished! Only one channel for now!
}

void ch_code (int ch, long freq)
{
	CORR_ch0_code_nco = freq;	//Not finished! Only one channel for now!
}

void ch_cntl (int ch, int data)
{
 	int G[37] = {
		0x3EC, 0x3D8, 0x3B0, 0x360, 0x096, 0x12C, 0x196, 0x32C, 0x258,
		0x374, 0x2E8, 0x3A0, 0x340, 0x280, 0x100, 0x200, 0x226,
		0x04C, 0x098, 0x130, 0x260, 0x0C0, 0x0CE, 0x270, 0x0E0,
		0x1C0, 0x380, 0x300, 0x056, 0x0AC, 0x158, 0x2B0, 0x160,
		0x0B0, 0x316, 0x22C, 0x0B0};
		CORR_ch0_prn_key = G[data-1];	//Not finished! Only one channel for now!
}

void program_TIC (long data)
{
	CORR_TIC_div = data;
}

void program_accum_int (long data)
{
	CORR_accum_int_div = data;
}

void full_reset (void)
{
	CORR_reset = 0;	//just send something. 
			//Reset is generated on every 
			//write-command to special reset address.
}

long get_status (void)
{
	return CORR_status;
}


