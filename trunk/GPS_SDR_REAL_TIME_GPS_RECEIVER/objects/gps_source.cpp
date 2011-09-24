/*----------------------------------------------------------------------------------------------*/
/*! \file gps_source.cpp
//
// FILENAME: gps_source.cpp
//
// DESCRIPTION: Implements member functions of the GPS_Source class.
//
// DEVELOPERS: Gregory W. Heckler (2003-2009)
//
// LICENSE TERMS: Copyright (c) Gregory W. Heckler 2009
//
// This file is part of the GPS Software Defined Radio (GPS-SDR)
//
// The GPS-SDR is free software; you can redistribute it and/or modify it under the terms of the
// GNU General Public License as published by the Free Software Foundation; either version 2 of
// the License, or (at your option) any later version. The GPS-SDR is distributed in the hope that
// it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
// more details.
//
// Note:  Comments within this file follow a syntax that is compatible with
//        DOXYGEN and are utilized for automated document extraction
//
// Reference:
*/
/*----------------------------------------------------------------------------------------------*/


#include "gps_source.h"


/*----------------------------------------------------------------------------------------------*/
GPS_Source::GPS_Source(Options_S *_opt)
{
	int i;

	memcpy(&opt, _opt, sizeof(Options_S));
	record_on = (opt.recorder==1);
	switch(opt.source)
	{
		case SOURCE_USRP_V1:
			source_type = SOURCE_USRP_V1;
			Open_USRP_V1();
			break;
		case SOURCE_USRP_V2:
//			source_type = SOURCE_USRP_V2;
//			Open_USRP_V2();
			break;
		case SOURCE_SIGE_GN3S :
			source_type = SOURCE_SIGE_GN3S;
			Open_GN3S();
			break;
		case SOURCE_FILE:
			source_type = SOURCE_FILE;
			Open_GPS_File();
			break;
		default:
			source_type = SOURCE_USRP_V1;
			Open_USRP_V1();
			break;
	}

	overflw = soverflw = 0;
	agc_scale = 1;

	/* Assign to base */
	buff_out_p = &buff_out[0];
	ms_count = 0;
	

	if(record_on)
	{
		// init record files
		
		out_file_a = fopen("./data.dba","wb");
		if(out_file_a != NULL) fprintf(stdout,"data.dba opened\n");
		if(opt.mode) // dual board
		{

			out_file_b = fopen("./data.dbb","wb");
			if(out_file_b != NULL) fprintf(stdout,"data.dbb opened\n");
		}		
		fflush(stdout);

	}


	if(opt.verbose)
		fprintf(stdout,"Creating GPS Source\n");

	for (i=0; i<1024; i=i+1) {
		sin_table[i] = -8*sin(2*M_PI*i/1024);
		cos_table[i] = +8*cos(2*M_PI*i/1024);
	}
	phase = 0;//2*M_PI*3889200/16000000;
	delta_phase = unsigned(2557223528);
}
/*----------------------------------------------------------------------------------------------*/


/*----------------------------------------------------------------------------------------------*/
GPS_Source::~GPS_Source()
{

	switch(source_type)
	{
		case SOURCE_USRP_V1:
			Close_USRP_V1();
			break;
		case SOURCE_USRP_V2:
//			Close_SOURCE_USRP_V2();
			break;
		case SOURCE_SIGE_GN3S :
			Close_GN3S();
			break;
		case SOURCE_FILE:
			Close_GPS_File();
			break;
		default:
			Close_USRP_V1();
			break;
	}

	if(opt.verbose)
		fprintf(stdout,"Destructing GPS Source\n");



	fclose(out_file_a);
}
/*----------------------------------------------------------------------------------------------*/


/*----------------------------------------------------------------------------------------------*/
void GPS_Source::Read(ms_packet *_p)
{

	double gain;
	int32 shift;
	CPX agc_buff[SAMPS_MS];
	switch(source_type)
	{
		case SOURCE_USRP_V1:
			Read_USRP_V1(_p);
			if(opt.mode == 1)
			{
				Read_USRP_V1(_p);
			}
			break;
		case SOURCE_USRP_V2:
//			Read_SOURCE_USRP_V2(_p);
			break;
		case SOURCE_SIGE_GN3S:
			Read_GN3S(_p);
			break;
		case SOURCE_FILE:
			Read_GPS_File(_p);
			break;
		default:
			Read_USRP_V1(_p);
			break;
	


	}

	if( record_on && (source_type != SOURCE_FILE) )
	{

		fwrite (&_p->data[0][0] , sizeof(CPX) , SAMPS_MS , out_file_a );

		if(opt.mode)
		{
			fwrite(&_p->data[1][0],sizeof(CPX),SAMPS_MS, out_file_b);
		}

	}



	//TODO: FIX THE AGC FOR MULTI INPUT STUFZ


	switch(source_type)
	{
		case SOURCE_USRP_V1:
			
			/* Count the overflows and shift if needed */
			soverflw += run_agc(&_p->data[0][0], SAMPS_MS, AGC_BITS, 6);
			
			/* Figure out the agc_scale value */
			if((ms_count & 0xFF) == 0)
			{
				gain = dbs_rx_a->rf_gain();

				if(soverflw > OVERFLOW_HIGH)
					gain -= 0.5;

				if(soverflw < OVERFLOW_LOW)
					gain += 0.5;

				dbs_rx_a->rf_gain(gain);

				agc_scale = (int32)floor(2.0*(dbs_rx_a->max_rf_gain() - gain));

				overflw = soverflw;
				soverflw = 0;
			}
			



			break;
		case SOURCE_USRP_V2:

//			Read_SOURCE_USRP_V2(_p);
			break;

		case SOURCE_SIGE_GN3S:

			break;
		case SOURCE_FILE:
			break;
		default:
			break;
	}


	ms_count++;

}
/*----------------------------------------------------------------------------------------------*/


/*----------------------------------------------------------------------------------------------*/
void GPS_Source::Open_USRP_V1()
{

	double ddc_correct_a = 0;
	double ddc_correct_b = 0;

	leftover = 0;

	if(opt.f_sample == 65.536e6)
	{
		if(opt.mode == 0)
		{
			sample_mode = 0;
			bwrite = 2048 * sizeof(CPX);
		}
		else
		{
			sample_mode = 1;
			bwrite = 4096 * sizeof(CPX);
			
		}
	}
	else
	{
		if(opt.mode == 0)
		{
			sample_mode = 2;
			bwrite = 2048 * sizeof(CPX);
		}
		else
		{
			sample_mode = 3;
			bwrite = 4096 * sizeof(CPX);
		}
	}

	/* Make the URX */
//Art!!! urx = usrp_standard_rx::make(0, opt.decimate, 1, -1, 0, 0, 0);
	urx = NULL;
	if(urx == NULL)
	{
		if(opt.verbose)
			fprintf(stdout,"usrp_standard_rx::make FAILED\n");
	}

	/* Set mux */
	urx->set_mux(0x32103210);

	/* N channels according to which mode we are operating in */
	if(opt.mode == 0)
		urx->set_nchannels(1);
	else
		urx->set_nchannels(2);

	/* Set the decimation */
	urx->set_decim_rate(opt.decimate);

	/* Setup board A */
	if(urx->daughterboard_id(0) == 2)
	{
		dbs_rx_a = new db_dbs_rx(urx, 0);

		/* Set the default master clock freq */
		dbs_rx_a->set_fpga_master_clock_freq(opt.f_sample);
		dbs_rx_a->set_refclk_divisor(16);
		dbs_rx_a->enable_refclk(true);

		/* Program the board */
		dbs_rx_a->bandwidth(opt.bandwidth);
		dbs_rx_a->if_gain(opt.gi);
		dbs_rx_a->rf_gain(opt.gr);
		dbs_rx_a->tune(opt.f_lo_a);

		/* Add additional frequency to ddc to account for imprecise LO programming */
		ddc_correct_a = dbs_rx_a->freq() - opt.f_lo_a;

		/* Set the DDC frequency */
		opt.f_ddc_a += ddc_correct_a;
		opt.f_ddc_a *= F_SAMPLE_NOM/opt.f_sample;

		if(opt.f_ddc_a > (F_SAMPLE_NOM/2.0))
			opt.f_ddc_a = F_SAMPLE_NOM - opt.f_ddc_a;

		urx->set_rx_freq(0, opt.f_ddc_a);

		/* Reset DDC phase to zero */
		urx->set_ddc_phase(0, 0);

		if(opt.verbose)
		{
			
			fprintf(stdout,"DBS-RX A Configuration\n");
			fprintf(stdout,"BW:      %15.2f\n",dbs_rx_a->bw());
			fprintf(stdout,"LO:      %15.2f\n",dbs_rx_a->freq());
			fprintf(stdout,"IF Gain: %15.2f\n",dbs_rx_a->if_gain());
			fprintf(stdout,"RF Gain: %15.2f\n",dbs_rx_a->rf_gain());
			fprintf(stdout,"DDC 0:   %15.2f\n",urx->rx_freq(0));
		}
	}

	/* Setup board B (if it exists) */
	if(urx->daughterboard_id(1) == 2)
	{
		
		dbs_rx_b = new db_dbs_rx(urx, 1);

		/* Even if you are not using board B, you need to enable the RF
		 * section else it screws up the CN0 on board A */
		if(opt.mode==0)
		{
			/* Set the default master clock freq */
			dbs_rx_b->set_fpga_master_clock_freq(opt.f_sample);
			dbs_rx_b->set_refclk_divisor(16);
			dbs_rx_b->enable_refclk(false);

			/* Program the board */
			dbs_rx_b->bandwidth(opt.bandwidth);
			dbs_rx_b->if_gain(opt.gi);
			dbs_rx_b->rf_gain(opt.gr);
			dbs_rx_b->tune(opt.f_lo_b);
		}
		else
		{
			/* Set the default master clock freq */
			dbs_rx_b->set_fpga_master_clock_freq(opt.f_sample);
			dbs_rx_b->set_refclk_divisor(16);
			dbs_rx_b->enable_refclk(true); // not good for L2 Clock

			/* Program the board */
			dbs_rx_b->bandwidth(opt.bandwidth);
			dbs_rx_b->if_gain(opt.gi);
			dbs_rx_b->rf_gain(opt.gr);
			dbs_rx_b->tune(opt.f_lo_b);

		}

		
		/* Dual board mode */
		if(opt.mode)
		{
		

			/* Add additional frequency to ddc to account for imprecise LO programming */
		
			ddc_correct_b = dbs_rx_b->freq() - opt.f_lo_b;

			/* Set the DDC frequency */
			opt.f_ddc_b += ddc_correct_b;
			opt.f_ddc_b *= F_SAMPLE_NOM/opt.f_sample;

			if(opt.f_ddc_b > (F_SAMPLE_NOM/2.0))
				opt.f_ddc_b = F_SAMPLE_NOM - opt.f_ddc_b;

			urx->set_rx_freq(1, opt.f_ddc_b);

			/* Set mux for both channels */
			urx->set_mux(0x32103210);

			urx->set_ddc_phase(1, 0);

			if(opt.verbose)
			{
				
				fprintf(stdout,"DBS-RX B Configuration\n");
				fprintf(stdout,"BW:      %15.2f\n",dbs_rx_b->bw());
				fprintf(stdout,"LO:      %15.2f\n",dbs_rx_b->freq());
				fprintf(stdout,"IF Gain: %15.2f\n",dbs_rx_b->if_gain());
				fprintf(stdout,"RF Gain: %15.2f\n",dbs_rx_b->rf_gain());
				fprintf(stdout,"DDC 1:   %15.2f\n",urx->rx_freq(1));

			}

		}
	}

	/* Start collecting data */
	fprintf(stdout,"USRP Start\n");

//	urx->start(); // moved to read_usrp_v1 june 2010 by MW

}
/*----------------------------------------------------------------------------------------------*/


/*----------------------------------------------------------------------------------------------*/
void GPS_Source::Open_GN3S()
{
	unsigned char bbbb[4];

	int32 lcv;
	const double mul = 8.1838e6/2.048e6;
	//const double mul = 16e6/2.048e6;

	/* Create the object */
	gn3s_a = new gn3s(0);

	/* Create decimation lookup table */
	for(lcv = 0; lcv < 10240; lcv++)
	{
		//gdec[lcv] = (int32)floor((double)lcv * mul);
		gdec[lcv] = (int32)floor((lcv+1)*4000/2048);
	}


	//fprintf(stdout, "Writing command words! /n");
    bbbb[0] = 0xA2; bbbb[1] = 0x91; bbbb[2] = 0x8F; bbbb[3] = 0x30;
    gn3s_a->write_cmd( 0x0C, 0, 0, bbbb, 4);
    bbbb[0] = 0x05; bbbb[1] = 0x50; bbbb[2] = 0x08; bbbb[3] = 0x81;
    gn3s_a->write_cmd(0x0C, 0, 0, bbbb, 4);
    bbbb[0] = 0xFE; bbbb[1] = 0xFF; bbbb[2] = 0x1D; bbbb[3] = 0xC2;
    gn3s_a->write_cmd(0x0C, 0, 0, bbbb, 4);
    bbbb[0] = 0x9E; bbbb[1] = 0xC0; bbbb[2] = 0x00; bbbb[3] = 0x83;
    gn3s_a->write_cmd(0x0C, 0, 0, bbbb, 4);
    bbbb[0] = 0x0C; bbbb[1] = 0x4A; bbbb[2] = 0x08; bbbb[3] = 0x04;
    gn3s_a->write_cmd(0x0C, 0, 0, bbbb, 4);
    bbbb[0] = 0x08; bbbb[1] = 0x00; bbbb[2] = 0x07; bbbb[3] = 0x05;
    gn3s_a->write_cmd(0x0C, 0, 0, bbbb, 4);
    bbbb[0] = 0x80; bbbb[1] = 0x00; bbbb[2] = 0x00; bbbb[3] = 0x06;
    gn3s_a->write_cmd(0x0C, 0, 0, bbbb, 4);
    bbbb[0] = 0x10; bbbb[1] = 0x06; bbbb[2] = 0x1B; bbbb[3] = 0x27;
    gn3s_a->write_cmd(0x0C, 0, 0, bbbb, 4);
    bbbb[0] = 0x1E; bbbb[1] = 0x0F; bbbb[2] = 0x40; bbbb[3] = 0x18;
    gn3s_a->write_cmd(0x0C, 0, 0, bbbb, 4);
    bbbb[0] = 0x14; bbbb[1] = 0xC0; bbbb[2] = 0x40; bbbb[3] = 0x29;
    gn3s_a->write_cmd(0x0C, 0, 0, bbbb, 4);



	/* Everything is super! */
	fprintf(stdout,"GN3S Start\n");

}
/*----------------------------------------------------------------------------------------------*/


/*----------------------------------------------------------------------------------------------*/
void GPS_Source::Open_GPS_File()
{
	

	fp_a = fopen(opt.file_name_1,"rb");	
	rewind(fp_a);
	

	if( opt.mode == 1)
	{
		fp_b = fopen(opt.file_name_2,"rb");
		//note only run dual file for same time as single
		rewind(fp_b);
	}

	//TODO: add some bulletproofing incase the file doesnt open


	return;
}
/*----------------------------------------------------------------------------------------------*/




/*----------------------------------------------------------------------------------------------*/
void GPS_Source::Close_USRP_V1()
{

	urx->stop();

	if(dbs_rx_a != NULL)
	{
		dbs_rx_a->enable_refclk(false);
		delete dbs_rx_a;
	}
	if(dbs_rx_b != NULL)
	{
		dbs_rx_b->enable_refclk(false);
		delete dbs_rx_b;
	}
	if(urx != NULL)
		delete urx;

	if(opt.verbose)
		fprintf(stdout,"Destructing USRP\n");

}
/*----------------------------------------------------------------------------------------------*/


/*----------------------------------------------------------------------------------------------*/
void GPS_Source::Close_GN3S()
{

	if(gn3s_a != NULL)
		delete gn3s_a;

	if(opt.verbose)
		fprintf(stdout,"Destructing GN3S\n");

}
/*----------------------------------------------------------------------------------------------*/


/*----------------------------------------------------------------------------------------------*/
void GPS_Source::Close_GPS_File()
{
	fclose(fp_a);	
	if( opt.mode == 1 )
	{
		fclose(fp_b);
	}
	return;


}
/*----------------------------------------------------------------------------------------------*/



/*----------------------------------------------------------------------------------------------*/
void GPS_Source::Read_USRP_V1(ms_packet *_p)
{

	bool overrun;

	/* There may be a packet waiting already, if so copy and return immediately */
	switch(sample_mode)
	{
		case 2:

			if(leftover > 4000)
			{
				Resample_USRP_V1(buff, buff_out);
				memcpy(&_p->data[0][0], buff_out, SAMPS_MS*sizeof(CPX));
				leftover -= 4000;
				memcpy(dbuff, &buff[4000], leftover*sizeof(int32));
				memcpy(buff, dbuff, leftover*sizeof(int32));
				return;
			}
			break;

		case 3:

			if(leftover > 8000)
			{
				Resample_USRP_V1(buff, buff_out);
				memcpy(&(_p->data[0][0]), buff_out, SAMPS_MS*sizeof(CPX));
				leftover -= 8000;
				memcpy(dbuff, &buff[8000], leftover*sizeof(int32));
	
			memcpy(buff, dbuff, leftover*sizeof(int32));
				return;
			}
			break;

		default:
			break;
	}



	if(!started)
	{
		//added to remove overflow on startup
		urx->start();
		started = 1;

	}
	


	

	
	urx->read(&buff[leftover], BYTES_PER_READ, &overrun);
	
	


	if(overrun && opt.verbose)
	{
		time(&rawtime);
		timeinfo = localtime (&rawtime);
		fprintf(stdout, "\nUSRP overflow at time %s",asctime (timeinfo));
	
	
	}
	fflush(stdout);
	/* Now we have SAMPS_PER_READ samps, 4 possible things to do depending on the state:
	 * 0) mode == 0 && f_sample == 65.536e6: This mode is the easiest, 1 ms of data per FIFO node,
	 * hence just call resample() and stuff in the pipe
	 * 1) mode == 1/2 && f_sample == 65.536e6: This mode is also easy, 2 nodes = 1 ms, hence buffer 2 nodes together
	 * and then call resample();
	 * 2) mode == 0 && f_sample == 64.0e6: 1 node is slightly larger (4096 vs 4000) than 1 ms, must first double
	 * buffer the data to extract continuous 4000 sample packets then call resample()
	 * 3) mode == 1/2 && f_sample == 64.0e6: must take 2 nodes, create 8192 sample buffer, and similarly extract 8000
	 * sample packet and call resample(), requires double buffering */
	switch(sample_mode)
	{
		case 0:
			Resample_USRP_V1(buff, buff_out);
			memcpy(&_p->data[0][0], buff_out, SAMPS_MS*sizeof(CPX));
			leftover = 0;
			break;
		case 1:
			
			leftover += 4096; leftover %= 2*4096;
			if(leftover == 0)
			{

				
				Resample_USRP_V1(buff, buff_out);
				
				memcpy(&_p->data[0][0], buff_out,2048*sizeof(CPX));
				memcpy(&_p->data[1][0], &buff_out[2048],2048*sizeof(CPX));
				
			}

			break;
		case 2:

			leftover += 96;
			Resample_USRP_V1(buff, buff_out);
			memcpy(&_p->data[0][0], buff_out, SAMPS_MS*sizeof(CPX));

			/* Move excess bytes at end of buffer down to the base */
			memcpy(dbuff, &buff[4000], leftover*sizeof(int32));
			memcpy(buff, dbuff, leftover*sizeof(int32));
			break;

		case 3:

			leftover += 192;
			Resample_USRP_V1(buff, buff_out);
			memcpy(&_p->data[0][0], buff_out, 2*SAMPS_MS*sizeof(CPX));

			/* Move excess bytes at end of buffer down to the base */
			memcpy(dbuff, &buff[8000], leftover*sizeof(int32));
			memcpy(buff, dbuff, leftover*sizeof(int32));
			break;

		default:
			break;
	}

}
/*----------------------------------------------------------------------------------------------*/


/*----------------------------------------------------------------------------------------------*/
void GPS_Source::Read_GN3S(ms_packet *_p)
{

	int32 bread, check;
	bool overrun;
	int32 ms_mod5;
	int32 lcv;
	//int16 LUT[4] = {1, -1, 1, -1};
	int16 LUT[4] = {-3, -1, 1, 3};
	int16 *pbuff;
	CPX mine_iq;

	ms_mod5 = ms_count % 5;

//	if(ms_count == 0)
//	{
		/* Start transfer */
/*		while(!started)
		{
			usleep(100);
			started = gn3s_a->usrp_xfer(VRQ_XFER, 1);
		}*/

		/* Make sure we are reading I0,Q0,I1,Q1,I2,Q2.... etc */
/*		bread = gn3s_a->read((void*)(&gbuff[0]),1);
		check = (gbuff[0] & 0x3);   //0 or 1 -> I sample , 2 or 3 -> Q sample
		if(check < 2)
		{
			bread = gn3s_a->read((void*)(&gbuff[0]),1);
		}*/
//	}

	//fprintf(stdout, "Attempt to read data... \n");
	/* Do the GN3S reading */
	if(ms_mod5 == 0)
	{
		//pbuff = (int16 *)&buff[7];
		//pbuff = (int16 *)&buff[0];

		/* Read 5 ms */
		//bread = gn3s_a->read((void *)&gbuff[0], 40919*2);
		bread = gn3s_a->read((void *)&gbuff[0], 20000);
		//fprintf(stdout, "Read %d bytes \n", bread);

		/* Convert to +-1 */
		/*for(lcv = 0; lcv < 40919*2; lcv++)
			pbuff[lcv] = LUT[gbuff[lcv] & 0x3];*/

		for(lcv = 0; lcv < 20000; lcv++){
			short_phase = phase >> 22;
//			mine_iq.i = (LUT[gbuff[lcv] & 0x03] * sin_table[short_phase]);
//			mine_iq.q = (LUT[gbuff[lcv] & 0x03] * cos_table[short_phase]);
			mine_iq.q = (LUT[gbuff[lcv] & 0x03] * sin_table[short_phase]);
			mine_iq.i = (LUT[gbuff[lcv] & 0x03] * cos_table[short_phase]);
			buff[lcv] = mine_iq;
			phase = phase + delta_phase;
		}

		/* Filter & decimate the data to regain bit precision */
		Resample_GN3S(&buff[0], &buff_out[0]);

		/* Move last 7 elements to the bottom */
		//memcpy(&buff[0], &buff[40919], 7*sizeof(CPX));

		/* Check the overrun */
/*		overrun = gn3s_a->check_rx_overrun();
		if(overrun && opt.verbose)
		{
			time(&rawtime);
			timeinfo = localtime (&rawtime);
			fprintf(stdout, "GN3S overflow at time %s\n", asctime(timeinfo));
			fflush(stdout);
		}*/

//		fwrite (buff_out, sizeof(CPX) , 10240 , out_file_a );
	}

	/* Move pointer */
	buff_out_p = &buff_out[SAMPS_MS*ms_mod5];

	/* Copy to destination */
	memcpy(&_p->data[0][0], buff_out_p, SAMPS_MS*sizeof(CPX));

}
/*----------------------------------------------------------------------------------------------*/


/*----------------------------------------------------------------------------------------------*/
void GPS_Source::Read_GPS_File(ms_packet *_p)
{
	
	

	
	fread(file_buff,sizeof(CPX),SAMPS_MS,fp_a);

	memcpy(&_p->data[0][0], file_buff, SAMPS_MS*sizeof(CPX));

	if( opt.mode == 2 )
	{
		fread(buff,sizeof(CPX),SAMPS_MS,fp_b);
		memcpy(&_p->data[1][0], file_buff, SAMPS_MS*sizeof(CPX));
	}

	/* Copy to destination */
	


	if(feof(fp_a))
	{	//once we hit end of file do a rewind!

		rewind(fp_a);
		if( opt.mode == 2) rewind(fp_b);
		fprintf(stdout,"Rewinding GPS Data File\n");
	}


	usleep(1000); // force a nap so we don't bust through this in 2 sec
}

/*----------------------------------------------------------------------------------------------*/




/*----------------------------------------------------------------------------------------------*/
void GPS_Source::Resample_USRP_V1(CPX *_in, CPX *_out)
{

	CPX buff_a[4096]; /* Max size based on 65.536 or 64 Msps */
	CPX buff_b[4096]; /* Max size based on 65.536 or 64 Msps */
	int32 *p_a;
	int32 *p_b;
	int32 *p_in;
	int32 *p_out, *p_out2;
	int32 samps_ms;
	int32 lcv;

	p_a = (int32 *)&buff_a[0];
	p_b = (int32 *)&buff_b[0];
	p_in = (int32 *)_in;
	p_out = (int32 *)_out;
	p_out2 = (int32 *)&_out[2048];
	samps_ms = (int32)floor(opt.f_sample/opt.decimate/1e3);

	if(opt.mode == 0)
	{
		/* Not much to do, just downsample from either 4.096 or 4.0 to 2.048e6 */
		if(opt.f_sample != 65.536e6)
			downsample(_out, _in, 2.048e6, opt.f_sample/opt.decimate, samps_ms);
		else
		{
			for(lcv = 0; lcv < samps_ms; lcv += 2)
				*p_out++ = p_in[lcv];
		}
	}
	else //!< 2 boards are being used, must first de-interleave data before downsampling
	{

	/* De-interleave */
		for(lcv = 0; lcv < samps_ms; lcv++)
		{
			p_a[lcv] = *p_in++;
			p_b[lcv] = *p_in++;
			
		}
		
		/* Downsample (and copy!) into appropriate location */
		
		
		downsample(&_out[0],    buff_a, 2.048e6, opt.f_sample/opt.decimate, samps_ms);
		downsample(&_out[2048], buff_b, 2.048e6, opt.f_sample/opt.decimate, samps_ms);
		
	
	}

}
/*----------------------------------------------------------------------------------------------*/


/*----------------------------------------------------------------------------------------------*/
/*void GPS_Source::Resample_GN3S(CPX *_in, CPX *_out)
{
	/* Runs specified filter on incoming signal. */
/*	int32 lcv, ind;
	int16 tmp;

	/* Process the array */
/*	for(lcv = 0; lcv < 10240; lcv++)
	{
		ind = gdec[lcv];

		tmp = 8;
		tmp += _in[ind +  6].i *  3;
		tmp += _in[ind +  5].i * 97;
		tmp += _in[ind +  4].i * 77;
		tmp += _in[ind +  3].i * 86;
		tmp += _in[ind +  2].i * 77;
		tmp += _in[ind +  1].i * 97;
		tmp += _in[ind +  0].i *  3;
		_out[lcv].i = tmp >> 4;

		tmp = 8;
		tmp += _in[ind +  6].q *  3;
		tmp += _in[ind +  5].q * 97;
		tmp += _in[ind +  4].q * 77;
		tmp += _in[ind +  3].q * 86;
		tmp += _in[ind +  2].q * 77;
		tmp += _in[ind +  1].q * 97;
		tmp += _in[ind +  0].q *  3;
		_out[lcv].q = tmp >> 4;

//		tmp = 4;
//		tmp += _in[ind + 12].i *   3;
//		tmp += _in[ind + 11].i *  -8;
//		tmp += _in[ind + 10].i * -11;
//		tmp += _in[ind +  9].i *   1;
//		tmp += _in[ind +  8].i *  26;
//		tmp += _in[ind +  7].i *  52;
//		tmp += _in[ind +  6].i *  63;
//		tmp += _in[ind +  5].i *  52;
//		tmp += _in[ind +  4].i *  26;
//		tmp += _in[ind +  3].i *  1;
//		tmp += _in[ind +  2].i * -11;
//		tmp += _in[ind +  1].i *  -8;
//		tmp += _in[ind +  0].i *   3;
//		_out[lcv].i = tmp >> 3;
//
//		tmp = 4;
//		tmp += _in[ind + 12].q *   3;
//		tmp += _in[ind + 11].q *  -8;
//		tmp += _in[ind + 10].q * -11;
//		tmp += _in[ind +  9].q *   1;
//		tmp += _in[ind +  8].q *  26;
//		tmp += _in[ind +  7].q *  52;
//		tmp += _in[ind +  6].q *  63;
//		tmp += _in[ind +  5].q *  52;
//		tmp += _in[ind +  4].q *  26;
//		tmp += _in[ind +  3].q *  1;
//		tmp += _in[ind +  2].q * -11;
//		tmp += _in[ind +  1].q *  -8;
//		tmp += _in[ind +  0].q *   3;
//		_out[lcv].q = tmp >> 3;

	}

	return;
}*/

void GPS_Source::Resample_GN3S(CPX *_in, CPX *_out)
{
	int i;
    /* Process the array */
	for(i = 0; i < 10240; i++)
	{
		_out[i] = _in[gdec[i]];
	}

	return;
}
/*----------------------------------------------------------------------------------------------*/
