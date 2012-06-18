/*
Engineer: Artyom Gavrilov, gnss-sdr.com, 2012
*/

#include <stdio.h>
#include <math.h>
#include "Vgps_baseband_16bit_async_mem_bus.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

//DEBUG CONTS:
#define DBG_PRN 0
#define DBG_STRT_CHNL 0

#define ENABLE_IQ_PROCESSING

// GLOBAL CONTANTS:
#define SYS_CLK_PERIODE 6250 //system clock periode in [ps] (80 MHz system clock).

#define sign(x) (x > 0 ? 1 : (x == 0) ? 0 : -1) // sign(x) function definition.

//=================Takuji Ebinuma code===========================================
#define NCO_RESOLUTION	0.074505806         // = 16MHz*5 / 2^30 //!(GavAI) in original code division coef=2^29 (why???)

#define CODE_REF		13730473UL  // = 1.023MHz / NCO_RESOLUTION
#define CARR_REF		34628173UL  // = 2.580MHz / NCO_RESOLUTION
#define CARR_REF_SIGN           0           // [Art] 1 - corresponds to +1 and 0 to -1.

#define NoiseFloor		13400  //[ART] 68750  // FIXME: Much larger than expected. Why?
#define AcqThresh		4*53600 //[ART]273699 // SNR = 6dB
#define LossThresh		26800 //[ART]137174 // SNR = 3dB

#define CodesrchStep	4    // = 500Hz / 1540 / NCO_RESOLUTION
#define CarrSrchStep	6711 // = 500Hz / NCO_RESOLUTION
#define CarrSrchWidth	20   // = 500Hz * 20 = +/-5kHz

#define PullInTime	3000 // = 3 seconds

#define outpw(A,D) bus_write(0x00000000+A, D); wait_clock_simple()
#define inpw(A) bus_read(0x00000000+A); wait_clock_simple()

#define PRN_KEY			0x00
#define CARR_NCO_LOW		0x02
#define CARR_NCO_HIGH		0x04
#define CODE_NCO_LOW		0x06
#define CODE_NCO_HIGH		0x08
#define CODE_SLEW		0x0A
#define I_EARLY			0x0C
#define Q_EARLY			0x0E
#define I_PROMPT		0x10
#define Q_PROMPT		0x12
#define I_LATE			0x14
#define Q_LATE			0x16
#define CARR_MEAS_LOW		0x18
#define CARR_MEAS_HIGH		0x1A
#define CODE_MEAS_LOW		0x1C
#define CODE_MEAS_HIGH		0x1E
#define EPOCH_MEAS		0x20
#define EPOCH_CHECK		0x22
#define EPOCH_LOAD		0x24

#define STATUS			0x232
#define NEW_DATA		0x234
#define TIC_COUNT_LOW		0x236
#define TIC_COUNT_HIGH		0x238
#define ACCUM_COUNT_LOW		0x23A
#define ACCUM_COUNT_HIGH	0x23C

#define RESET			0x220
#define PROG_TIC_LOW		0x222
#define PROG_TIC_HIGH		0x224
#define PROG_ACCUM_INT_LOW	0x226
#define PROG_ACCUM_INT_HIGH	0x228

#define NO_LOCK			0x00
#define CODE_LOCK		0x01
#define CARR_LOCK		0x02
#define PHASE_LOCK		0x04
#define BIT_SYNC		0x08
#define FRAME_SYNC		0x10

#define IDLE			0

#define FALSE			0
#define TRUE			1

#define MAX_CHANNELS	1
#define MAX_SATELLITES	32

unsigned short prntaps[MAX_SATELLITES] =
     {0x3EC, 0x3D8, 0x3B0, 0x360,
      0x096, 0x12C, 0x196, 0x32C,
      0x258, 0x374, 0x2E8, 0x3A0,
      0x340, 0x280, 0x100, 0x200,
      0x226, 0x04C, 0x098, 0x130,
      0x260, 0x0C0, 0x0CE, 0x270,
      0x0E0, 0x1C0, 0x380, 0x300,
      0x056, 0x0AC, 0x158, 0x2B0};

typedef struct
{
	unsigned long BASE;
	int prn;
	unsigned short lock_status;
	long pow_code,pow_carr;
	unsigned long carr_nco,code_nco;
        int carr_nco_sign; //[Art]. IQ-processing rough addition.
	long IP,QP;
	long E,Tau;
	unsigned short pull_in_time;
	unsigned short half_chip_counter;
	unsigned short freq_bin_counter;
} channel_t;

unsigned short status;
channel_t CH[MAX_CHANNELS];
//=================Takuji Ebinuma code END=======================================

// GLOBAL VARIABLES:
Vgps_baseband_16bit_async_mem_bus* top;
VerilatedVcdC* tfp;

vluint64_t sys_cycle_count;  // global variable for counting current cycle.
bool start_int_processing;   // start interrupt processing after all correlator settings are made:
char IF[32000];              // array with GPS signal samples to be processed.
                             // The size is chosen in order to store 1ms of IQ-data.

// gnss-file with signal record:
FILE *ifdata;
char IF_Filename[255] = "/home/Artyom/verilator/-2.58e6_iq_16e6.DAT"; // Name of the file with GPS signal record.
int ifdata_curr_pos;                                                  // Current position in the IF-buffer.

// output file for external analysis:
FILE *extfile;
char EXT_Filename[255] = "/home/Artyom/verilator/corr_rslts.TXT"; // Name of the file in which data will be recorded.

// Some helpful functions definitions:
void wait_clock();
void wait_clock_simple();
void bus_write(int address, int data);
short int bus_read(int address);
void read_sample_from_file(unsigned char *i, unsigned char *q);
void alloc_task();
void accum_task();
long fix_atan2 (long y, long x);
long labs (long x);

//=======================Some helpful functions:===============================
//=============================================================================
/******************************************************************************
FUNCTION   void wait_clock()

RETURNS    None.

PARAMETERS None.

PURPOSE
           Make 1 clock cycle including interrupt processing if required and
           reading gnss-signal samples from the file.

WRITTEN BY

           Gavrilov Artyom.

******************************************************************************/
void wait_clock()
{
  // check if we have interrupt request:
  if (start_int_processing) { // start interrupt processing only after correlator is initialized! 
                              // Otherwise wishbone cross requests problem will ocuure!
    if (top->accum_int == 1) {
      accum_task();
    }
  }

  // read next I/Q samples
  #ifndef ENABLE_IQ_PROCESSING
  read_sample_from_file(&top->mag, &top->sign);  //read I-sample only;
  #else
  read_sample_from_file(&top->mag, &top->mag_q); //read I-sample and Q-sample;
  #endif

  sys_cycle_count++; // go to next time tick;
  
  for (int clk=0; clk<2; clk++) {
    ///tfp->dump ((2*sys_cycle_count+clk)*SYS_CLK_PERIODE);//comment during long simultions!
    top->clk = !top->clk;
    top->eval ();
  }
}

/*Make 1 clock cycle. Differs from previous one by not checking interrupt pin*/
/******************************************************************************
FUNCTION    void wait_clock_simple()

RETURNS     None.

PARAMETERS  None.

PURPOSE
            Make 1 clock cycle WITHOUT interrupt processing!
            But with reading gnss-signal samples from the file.

WRITTEN BY

            Gavrilov Artyom.

******************************************************************************/
void wait_clock_simple()
{
  // read next I/Q samples
  #ifndef ENABLE_IQ_PROCESSING
  read_sample_from_file(&top->mag, &top->sign);  //read I-sample only;
  #else
  read_sample_from_file(&top->mag, &top->mag_q); //read I-sample and Q-sample;
  #endif

  sys_cycle_count++; // go to next time tick;
 
  for (int clk=0; clk<2; clk++) {
    ///tfp->dump ((2*sys_cycle_count+clk)*SYS_CLK_PERIODE);//comment during long simultions!
    top->clk = !top->clk;
    top->eval ();
  }
}

/******************************************************************************
FUNCTION   void bus_write(int address, int data)

RETURNS    None.

PARAMETERS address - address in memory where data should be written.
           data    - data to be written.

PURPOSE
           Async memory bus write function.

WRITTEN BY

           Gavrilov Artyom. Based on MM SoC sources.

******************************************************************************/
void bus_write(int address, int data)
{
  top->address_a   = address;
  top->data        = data;
  top->wen_a       = 0;
  top->oen_a       = 1;
  top->csn_a       = 0;
  
  wait_clock_simple();
  wait_clock_simple();
  wait_clock_simple();
  
  top->wen_a = 1;
  top->oen_a = 1;
  top->csn_a = 1;

  wait_clock_simple();
  wait_clock_simple();
}

/******************************************************************************
FUNCTION   int bus_read(int address)

RETURNS    Read data.

PARAMETERS address - address in memory from where data should be read.

PURPOSE
           Async memory bus read function

WRITTEN BY

           Gavrilov Artyom. Based on MM SoC sources.

******************************************************************************/
short int bus_read(int address)
{
  top->address_a = address;
  top->wen_a     = 1;
  top->oen_a     = 0;
  top->csn_a     = 0;
  
  wait_clock_simple();
  
  top->wen_a = 1;
  top->oen_a = 1;
  top->csn_a = 1;
  
  wait_clock_simple();
  wait_clock_simple();

  return top->data_out;
}

/*Read 1 sample from file containing gnss signal record*/
/******************************************************************************
FUNCTION   void read_sample_from_file(char *i, char *q)

RETURNS    None.

PARAMETERS Two samples to be read.

PURPOSE
           Read data from external file and send it to correlator input.

WRITTEN BY

           Gavrilov Artyom.

******************************************************************************/
void read_sample_from_file(unsigned char *i, unsigned char *q)
{
  static int div_ratio = -1;

  if (ifdata_curr_pos == 16000) {
    fread(&IF, sizeof(char), 32000, ifdata);
    ifdata_curr_pos = 0;
  }
/*  #ifndef ENABLE_IQ_PROCESSING
  *q = 0;
  #else
  *q = ( IF[2*ifdata_curr_pos]   > 0 ? 1 : 0 ); //1-bit quantization for now...
  #endif
  *i = ( IF[2*ifdata_curr_pos+1] > 0 ? 1 : 0 ); //1-bit quantization for now...*/


  #ifndef ENABLE_IQ_PROCESSING
  *q = 0;
  #else
  *q = ( IF[2*ifdata_curr_pos]   > 0 ? 1 : 0 ); //1-bit quantization for now...
  #endif
  *i = ( IF[2*ifdata_curr_pos+1] > 0 ? 1 : 0 ); //1-bit quantization for now...




  if (++div_ratio == 5){
    ifdata_curr_pos++;
    div_ratio = 0;
  }

//debug:
  top->test_point_002 = 2*ifdata_curr_pos;
  top->test_point_003 = div_ratio;
}

/******************************************************************************
FUNCTION   void alloc_task()

RETURNS    None.

PARAMETERS None.

PURPOSE
           Allocate channels.

WRITTEN BY

           Takuji Ebinuma.

******************************************************************************/
void alloc_task()
{
  int i,k,already_allocated;
  static int sv = 15;//0; //[Art] to reduce acquisition time!
  int sv_index[2] = {27, 17};
  
  ///while (1) {
    for (i=0; i<MAX_CHANNELS; i++) {
      if (CH[i].prn==IDLE) {
        CH[i].lock_status = NO_LOCK;
        CH[i].pow_code = LossThresh;
        CH[i].pow_carr = LossThresh;
        CH[i].IP = 0;
        CH[i].QP = 0;
        CH[i].E= 0;
        CH[i].Tau = 0;
        CH[i].half_chip_counter = 0;
        CH[i].freq_bin_counter = 0;
        CH[i].pull_in_time = 0;
        CH[i].carr_nco = CARR_REF + CarrSrchStep*2; //[Art] to reduce acquisition time!
        CH[i].code_nco = CODE_REF;
        
        outpw((CH[i].BASE+PRN_KEY), prntaps[sv]);
        ///outpw((CH[i].BASE+CARR_NCO), CH[i].carr_nco);
        outpw((CH[i].BASE+CARR_NCO_LOW),  (CH[i].carr_nco & 0x0000ffff));
        ///outpw((CH[i].BASE+CARR_NCO_HIGH), ((CH[i].carr_nco & 0xffff0000)>>16));
        if (CH[i].carr_nco_sign > 0 ){
          outpw((CH[i].BASE+CARR_NCO_HIGH), ( ((CH[i].carr_nco & 0xffff0000)>>16) | (1<<15) )); //[Art]. (1<<15) is the sign!
        }                                                                                       //of the NCO freq.
        else {
          outpw((CH[i].BASE+CARR_NCO_HIGH), ((CH[i].carr_nco & 0xffff0000)>>16));
        }

        ///outpw((CH[i].BASE+CODE_NCO), CH[i].code_nco);
        outpw((CH[i].BASE+CODE_NCO_LOW),  (CH[i].code_nco & 0x0000ffff));
        outpw((CH[i].BASE+CODE_NCO_HIGH), ((CH[i].code_nco & 0xffff0000)>>16));
        
        CH[i].prn = sv+1;//[Art]temporary commented.
        //CH[i].prn = sv_index[0];
        //CH[i].prn =  sv_index[i];
        printf("PRN# %d \n", CH[i].prn);
        
        // Search the next unallocated satellite
        do {
          //sv++;
          sv=sv+10;
          if (sv==MAX_SATELLITES)
          sv = 0;
          
          already_allocated = FALSE;
          
          for (k=0; k<MAX_CHANNELS; k++) {
            if (sv==CH[k].prn-1) {
              already_allocated = TRUE;
              break;
            }
          }
        } while (already_allocated);
      }
    }
    
    ///OSTimeDlyHMSM(0, 0, 1, 0);
  ///}
}

/******************************************************************************
FUNCTION   void accum_task()

RETURNS    None.

PARAMETERS None.

PURPOSE
           Process interrupt request from correlator

WRITTEN BY

           Takuji Ebinuma.

******************************************************************************/
void accum_task()
{
  ///INT8U err;
  unsigned short new_data;
  unsigned short current_epoch[MAX_CHANNELS];
  long IP[MAX_CHANNELS],QP[MAX_CHANNELS];
  long IE[MAX_CHANNELS],QE[MAX_CHANNELS];
  long IL[MAX_CHANNELS],QL[MAX_CHANNELS];
  int i;
  unsigned short channel_mask;

  ///while (1) {
    ///OSSemPend(SemISR, 0, &err);

    // Check status register for a TIC
    status = (unsigned short)inpw(STATUS);/// Drop interrupt. [GavAI]
    ///if (status&0x1)
    ///  OSSemPost(SemMeas);

    // NEW_DATA register shows which channels have new accumulation data available
    new_data = (unsigned short)inpw(NEW_DATA);
    //printf("new_data = %d \n", new_data);//[Art] Debug.

    // Get and store the accumulation data
    channel_mask = 0x1;
    channel_mask <<= DBG_STRT_CHNL; //[Art]temporary.

    for (i=0; i<MAX_CHANNELS; i++) {
      if (new_data&channel_mask) {
        current_epoch[i] = (unsigned short)inpw((CH[i].BASE+EPOCH_CHECK));
        
        IP[i] = (long)(short)inpw((CH[i].BASE+I_PROMPT));
        QP[i] = (long)(short)inpw((CH[i].BASE+Q_PROMPT));
        IE[i] = (long)(short)inpw((CH[i].BASE+I_EARLY));
        QE[i] = (long)(short)inpw((CH[i].BASE+Q_EARLY));
        IL[i] = (long)(short)inpw((CH[i].BASE+I_LATE));
        QL[i] = (long)(short)inpw((CH[i].BASE+Q_LATE));
        if (i==DBG_PRN) fprintf(extfile, "%d, %d, %d, %d, %d, %d, ", IE[i], QE[i], IP[i], QP[i], IL[i], QL[i]);//[Art!]
        /*if (i==1)*////printf("%d\t %d, %d, %d, %d, %d, %d\n", i, IE[i], QE[i], IP[i], QP[i], IL[i], QL[i]);//[Art!]
        //printf("#%d\n", i);

        // Scale for fixed-point arithmetic
        IP[i] >>= 2;
        QP[i] >>= 2;
        IE[i] >>= 2;
        QE[i] >>= 2;
        IL[i] >>= 2;
        QL[i] >>= 2;
      }

      channel_mask <<= 1;
      //printf("#%d\n", i);
    }
    //printf("IP1 %d \t QP1 %d \t IP2 %d \t QP2 %d \n", IP[0], QP[0], IP[1], QP[1]);

    // Update the carrier and code tracking loops
    channel_mask = 0x1;
    channel_mask <<= DBG_STRT_CHNL; //[Art]temporary.

    for (i=0; i<MAX_CHANNELS; i++) {
      if (new_data&channel_mask) {
        long pow_code;
        long pow_carr;
        
        // Get instantaneous signal power
        pow_code = IP[i]*IP[i] + QP[i]*QP[i];
        top->test_point_001 = pow_code;//[Art] for debugging!.
        if (i==DBG_PRN) fprintf(extfile, "%d, ", pow_code);
        
        if (CH[i].lock_status&CODE_LOCK) {
          // Average noisy signal power
          CH[i].pow_code += (pow_code - CH[i].pow_code + 128L)>>8;
          
          // Use inner product for carrier lock indicator
          pow_carr = IP[i]*CH[i].IP + QP[i]*CH[i].QP;
          CH[i].pow_carr += (pow_carr - CH[i].pow_carr + 128L)>>8;
          if (i==DBG_PRN) fprintf(extfile, "%d, ", pow_carr);//[ART] for debugging!
        } else {if (i==DBG_PRN) fprintf(extfile, "%d, ", 0);}//[ART] for debugging! }
        
        if ((pow_code > AcqThresh) && !(CH[i].lock_status&CODE_LOCK)) {
          CH[i].lock_status = CODE_LOCK;
          CH[i].pow_code = LossThresh;
          CH[i].pow_carr = LossThresh;
          CH[i].Tau = 0;
        }
        else if (CH[i].pow_code < LossThresh)
          CH[i].lock_status = NO_LOCK;
        
        if (CH[i].lock_status&CODE_LOCK) {
          if ((CH[i].pow_carr > AcqThresh) && !(CH[i].lock_status&CARR_LOCK)) {
            CH[i].lock_status = (CARR_LOCK|CODE_LOCK);
            CH[i].pull_in_time = 0;
          }
          else if (CH[i].pow_carr < LossThresh)
            CH[i].lock_status = CODE_LOCK;
        }
        
        if ((CH[i].lock_status&CARR_LOCK) && !(CH[i].lock_status&PHASE_LOCK)) {
          CH[i].pull_in_time++;
          
          if (CH[i].pull_in_time>PullInTime) { // FIXME: Need better way to switch to phase tracking
            CH[i].lock_status = (PHASE_LOCK|CARR_LOCK|CODE_LOCK);
            CH[i].E = 0;
          }
        }

        if (i==DBG_PRN) fprintf(extfile, "%d\n", CH[i].lock_status);//[ART] for debugging!

        // If code lock has been achieved then update the tracking loops
        if (CH[i].lock_status&CODE_LOCK) {
          long ltemp;
          long E,F,Tau;
          long delta_carr_nco,delta_code_nco;

        // 2nd-order PLL with 1-st order FLL aiding:        
        // B_pll = 25 Hz, B_fll = 1Hz;
        // wn_pll = 1.86*B, wn_fll = 4*B
        // x(i)_pll = = sign(I)*Q
        // x(i)_fll = = 1/T * (Q(i)*I(i-1) - I(i)*Q(i-1))
        // T = 1ms
        // y(i)-y(i-1) = -(1.414*wn*(x(i)_pll-x(i-1)_pll) + wn^2*T*x(i)_pll) + wn*T*x(i)_fll
        {
          ///ltemp = sign(IP[i])*QP[i];
          ltemp = -sign(QP[i])*IP[i];
          
          E = ltemp<<11;
          
          ltemp = (E - CH[i].E) + ((E + 16L)>>5);
          
          CH[i].E = E;

          F = QP[i]*CH[i].IP - IP[i]*CH[i].QP;
        }

        delta_carr_nco = -((ltemp + 16384L)>>15) + ((F + 8192L)>>14);


          // [Art comment]. As IQ-processing needs additional sign information, 
          // this operation must be done carefully if this value is close to zero.
          // As in this case possible change of sign must be detected and processed!!!
          ///CH[i].carr_nco += delta_carr_nco; 
          if (CH[i].carr_nco_sign) //[Art] Take into account sign of the carrier freq in iq-signal-procesing-mode:
            CH[i].carr_nco += delta_carr_nco; 
          else
            CH[i].carr_nco -= delta_carr_nco;
          
          
          // 2nd-order delay lock loop:
          // y(i)-y(i-1) = 1.414*wn*(x(i)-x(i-1)) + wn^2*T*x(i)
          // x(i) = (IE - IL)*IP + (QE - QL)*QP
          // wn = 1.86*B, B = 1Hz
          // T = 1ms
          
          ltemp = (IE[i] - IL[i])*IP[i] + (QE[i] - QL[i])*QP[i];
          
          Tau = ltemp<<7;
          
          ltemp = (Tau - CH[i].Tau) + ((Tau + 256L)>>9);
          
          CH[i].Tau = Tau;
          
          delta_code_nco = (ltemp + 524288L)>>20;
          
          CH[i].code_nco += delta_code_nco;
        }
        else { // No code lock
          // Update the code phase
          outpw((CH[i].BASE+CODE_SLEW),1);
          
          // Increment the amount of code searched
          CH[i].half_chip_counter++;
          
          if (CH[i].half_chip_counter > 2045) {
            short f_bin;
            
            // Reset the amount of code searched
            CH[i].half_chip_counter = 0;
            
            // Increment the frequency bin
            CH[i].freq_bin_counter++;
            
            // Check if all frequency bins have been searched
            if (CH[i].freq_bin_counter > CarrSrchWidth) {
              CH[i].prn = IDLE;
              CH[i].freq_bin_counter = 0;
              alloc_task();/// Run chanel relocation function [GavAI].
            }
            
            // Get the code and carrier NCO offset
            if (CH[i].freq_bin_counter & 0x01)
              f_bin = 1 + CH[i].freq_bin_counter/2;
            else
              f_bin = -CH[i].freq_bin_counter/2;
              
            CH[i].code_nco = CODE_REF + CodesrchStep*f_bin;
            CH[i].carr_nco = CARR_REF + CarrSrchStep*f_bin;
          }
        }
        
        // Process the navigation message bit stream
        // ....
        
        // Save the current prompt arms
        CH[i].IP = IP[i];
        CH[i].QP = QP[i];
        
        // Update the carrier NCO
        ///outpw((CH[i].BASE+CARR_NCO), CH[i].carr_nco);
        outpw((CH[i].BASE+CARR_NCO_LOW),  (CH[i].carr_nco & 0x0000ffff));
        ///outpw((CH[i].BASE+CARR_NCO_HIGH), ((CH[i].carr_nco & 0xffff0000)>>16));[Art]
        if (CH[i].carr_nco_sign > 0 ){
          outpw((CH[i].BASE+CARR_NCO_HIGH), ( ((CH[i].carr_nco & 0xffff0000)>>16) | (1<<15) )); //[Art]. (1<<15) is the sign!
        }                                                                                       //of the NCO freq.
        else {
          outpw((CH[i].BASE+CARR_NCO_HIGH), ((CH[i].carr_nco & 0xffff0000)>>16));
        }
        //printf("%d \t %d \n", CH[i].carr_nco_sign, top->test_point_02);//[Art]. Debug.
        
        // Update the code NCO
        ///outpw((CH[i].BASE+CODE_NCO), CH[i].code_nco);
        outpw((CH[i].BASE+CODE_NCO_LOW),  (CH[i].code_nco & 0x0000ffff));
        outpw((CH[i].BASE+CODE_NCO_HIGH), ((CH[i].code_nco & 0xffff0000)>>16));
      }
      
      channel_mask <<= 1;
    }
  ///}

  ///start_int_processing = true;
}


//==========================MAIN=========================================

int main(int argc, char **argv, char **env) {
  int i;
  int clk;
  bool run;
  int gps_sample_i, gps_sample_q;

  Verilated::commandArgs(argc, argv);
  // init top verilog instance
  top = new Vgps_baseband_16bit_async_mem_bus;
  // init trace dump
  Verilated::traceEverOn(true);
  tfp = new VerilatedVcdC;
  tfp->spTrace()->set_time_resolution ("1 ps"); // set simulation time resolution to 1 ps.

  top->trace (tfp, 99);
  tfp->open ("gps_baseband_16bit_async_mem_bus.vcd");
  // initialize simulation inputs
  top->clk     = 1;
  top->hw_rstn = 0;
  top->wen_a   = 1;
  top->oen_a   = 1;
  top->csn_a   = 1;
  wait_clock_simple();//[Art]

  // open file for reading
  ifdata=fopen(IF_Filename,"rb");
  // open file for writing:
  extfile=fopen(EXT_Filename, "w");

  // run main simulation loop
  run = true; sys_cycle_count = 0; start_int_processing = false; ifdata_curr_pos = 16000;

  // drop reset:
  sys_cycle_count = 4; top->hw_rstn = 1;
  wait_clock_simple();//[Art]
  wait_clock_simple();//[Art]
  wait_clock_simple();//[Art]
  
  // async memory bus test:
  bus_write(0x00000300, 0x11111111); wait_clock();
  bus_write(0x00000302, 0x22222222); wait_clock();
  bus_write(0x00000304, 0x33333333); wait_clock();
  bus_write(0x00000306, 0x44444444); wait_clock();
  bus_write(0x00000308, 0x55555555); wait_clock();
  bus_write(0x0000030A, 0x66666666); wait_clock();
  bus_write(0x0000030C, 0x77777777); wait_clock();
  bus_write(0x0000030E, 0x88888888); wait_clock();
  bus_read(0x00000310); wait_clock();
  bus_read(0x00000312); wait_clock();
  bus_read(0x00000314); wait_clock();
  bus_read(0x00000316); wait_clock();
  bus_read(0x00000318); wait_clock();
  bus_read(0x0000031A); wait_clock();
  bus_read(0x0000031C); wait_clock();
  bus_read(0x0000031E); wait_clock();

//=================Takuji Ebinuma code===========================================
  // Reset baseband processor:
  outpw(RESET, 0);
  // Set ACCUM_INT for 800us:
  ///outpw(PROG_ACCUM_INT, 63999L);  // = (16MHz * 5) * 800us - 1
  outpw(PROG_ACCUM_INT_LOW,  (63999L & 0x0000ffff));      // = (16MHz * 5) * 800us - 1
  outpw(PROG_ACCUM_INT_HIGH, ((63999L & 0xffff0000)>>16));// = (16MHz * 5) * 800us - 1
  // Set PROG_TIC counter for 0.1s:
  ///outpw(PROG_TIC, 7999999L);      // = (16MHz * 5) * 0.1s - 1
  outpw(PROG_TIC_LOW,  (7999999L & 0x0000ffff));      // = (16MHz * 5) * 0.1s - 1
  outpw(PROG_TIC_HIGH, ((7999999L & 0xffff0000)>>16));// = (16MHz * 5) * 0.1s - 1
  // Initialize channels:
  for (int i=0; i<MAX_CHANNELS; i++) {
    //CH[i].BASE              = 0x10*i;
    CH[i].BASE              = 0x26*(i+DBG_STRT_CHNL);
    CH[i].prn               = IDLE;
    CH[i].lock_status       = NO_LOCK;
    CH[i].pow_code          = LossThresh;
    CH[i].pow_carr          = LossThresh;
    CH[i].IP                = 0;
    CH[i].QP                = 0;
    CH[i].E                 = 0;
    CH[i].Tau               = 0;
    CH[i].half_chip_counter = 0;
    CH[i].freq_bin_counter  = 0;
    CH[i].pull_in_time      = 0;
    CH[i].carr_nco_sign     = CARR_REF_SIGN; //[Art]. IQ-processing rough addition.
    ///CH[i].carr_nco_sign     = 0; //[Art]. Test.
    CH[i].carr_nco          = CARR_REF;
    CH[i].code_nco          = CODE_REF;
  }
//=================Takuji Ebinuma code END=======================================

  alloc_task();//test addition! [Art]

  //allow interrupt processing:
  start_int_processing = true;

  while(run) {
    // dump variables into VCD file and toggle clock
    wait_clock();

    if (sys_cycle_count == 8500*80000) run = false;

    if (Verilated::gotFinish())  exit(0);
  }
  tfp->close();
  fclose(ifdata);
  fclose(extfile);
  exit(0);
}
