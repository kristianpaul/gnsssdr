/*
TNKernel real-time kernel - examples

Copyright � 2004,2005 Yuri Tiomkin
All rights reserved.

Permission to use, copy, modify, and distribute this software in source
and binary forms and its documentation for any purpose and without fee
is hereby granted, provided that the above copyright notice appear
in all copies and that both that copyright notice and this permission
notice appear in supporting documentation.

THIS SOFTWARE IS PROVIDED BY THE YURI TIOMKIN AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL YURI TIOMKIN OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.
*/

/*============================================================================
  tst8.c (demo)
  GPS control program. (Only tracking loops are implemented currently)

  Note that for debug purpose Makefile was changed (-O1 key changed to -O0 and
  -g key was added).
*===========================================================================*/

#include "LPC24xx.h"
#include "utils.h"
#include "../TNKernel/tn.h"
#include <math.h>

// GLOBAL CONTANTS:
#define sign(x) (x > 0 ? 1 : (x == 0) ? 0 : -1) // sign(x) function definition.

//=================Takuji Ebinuma code===========================================
#define NCO_RESOLUTION  0.074505806         // = 16MHz*5 / 2^30 //!(GavAI) in original code division coef=2^29 (why???)

#define CODE_REF                13730473UL  // = 1.023MHz / NCO_RESOLUTION
#define CARR_REF                32480690UL  // = 2.420MHz / NCO_RESOLUTION

#define NoiseFloor              13400 //[ART] 68750  // FIXME: Much larger than expected. Why?
#define AcqThresh               53600 //[ART]273699 // SNR = 6dB
#define LossThresh              26800 //[ART]137174 // SNR = 3dB

#define CodesrchStep            4    // = 500Hz / 1540 / NCO_RESOLUTION
#define CarrSrchStep            6711 // = 500Hz / NCO_RESOLUTION
#define CarrSrchWidth           20   // = 500Hz * 20 = +/-5kHz

#define PullInTime              3000 // = 3 seconds

#define outpw(A,D) async_mem_write(0x80000000+A, D); //[Art]
#define inpw(A)    async_mem_read(0x80000000+A);     //[Art]

#define PRN_KEY                 0x00
#define CARR_NCO_LOW            0x02
#define CARR_NCO_HIGH           0x04
#define CODE_NCO_LOW            0x06
#define CODE_NCO_HIGH           0x08
#define CODE_SLEW               0x0A
#define I_EARLY                 0x0C
#define Q_EARLY                 0x0E
#define I_PROMPT                0x10
#define Q_PROMPT                0x12
#define I_LATE                  0x14
#define Q_LATE                  0x16
#define CARR_MEAS_LOW           0x18
#define CARR_MEAS_HIGH          0x1A
#define CODE_MEAS_LOW           0x1C
#define CODE_MEAS_HIGH          0x1E
#define EPOCH_MEAS              0x20
#define EPOCH_CHECK             0x22
#define EPOCH_LOAD              0x24

#define STATUS                  0x232
#define NEW_DATA                0x234
#define TIC_COUNT_LOW           0x236
#define TIC_COUNT_HIGH          0x238
#define ACCUM_COUNT_LOW         0x23A
#define ACCUM_COUNT_HIGH        0x23C

#define RESET                   0x220
#define PROG_TIC_LOW            0x222
#define PROG_TIC_HIGH           0x224
#define PROG_ACCUM_INT_LOW      0x226
#define PROG_ACCUM_INT_HIGH     0x228

#define NO_LOCK                 0x00
#define CODE_LOCK               0x01
#define CARR_LOCK               0x02
#define PHASE_LOCK              0x04
#define BIT_SYNC                0x08
#define FRAME_SYNC              0x10

#define IDLE                    0

#define FALSE                   0
#define TRUE                    1

#define MAX_CHANNELS    10
#define MAX_SATELLITES  32

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
        long IP,QP;
        long E,Tau;
        unsigned short pull_in_time;
        unsigned short half_chip_counter;
        unsigned short freq_bin_counter;
} channel_t;

//--- Non OS globals ---[Art]
unsigned short status;
channel_t CH[MAX_CHANNELS];
//=================Takuji Ebinuma code END=======================================

//----------- Tasks ----------------------------------------------------------

#define  TASK_LED1_PRIORITY         10
#define  TASK_UART_TX_PRIORITY      8
#define  TASK_CHECKMEM_PRIORITY     9
//GPS
#define  TASK_ACCUM_PRIORITY        1
#define  TASK_MEAS_PRIORITY         2
#define  TASK_DISP_PRIORITY         4
#define  TASK_ALLOC_PRIORITY        5

#define  TASK_LED1_STK_SIZE         128
#define  TASK_UART_TX_STK_SIZE      128
#define TASK_CHECKMEM_STK_SIZE      256
//GPS
#define TASK_ACCUM_STK_SIZE         2048
#define TASK_MEAS_STK_SIZE          2048
#define TASK_DISP_STK_SIZE          2048
#define TASK_ALLOC_STK_SIZE         2048

unsigned int task_led1_stack[TASK_LED1_STK_SIZE];
unsigned int task_uart_tx_stack[TASK_UART_TX_STK_SIZE];
unsigned int task_checkmem_stack[TASK_CHECKMEM_STK_SIZE];
//GPS
unsigned int task_accum_stack[TASK_ACCUM_STK_SIZE];
unsigned int task_meas_stack[TASK_MEAS_STK_SIZE];
unsigned int task_disp_stack[TASK_DISP_STK_SIZE];
unsigned int task_alloc_stack[TASK_ALLOC_STK_SIZE];


TN_TCB  task_led1;
TN_TCB  task_uart_tx;
TN_TCB task_checkmem;
//GPS
TN_TCB task_accum;
TN_TCB task_meas;
TN_TCB task_disp;
TN_TCB task_alloc;

void task_led1_func(void *par);
void task_uart_rx_func(void * par);
void task_uart_tx_func(void * par);
void task_checkmem_func(void *par);
//GPS
void task_accum_func(void *par);
void task_meas_func(void *par);
void task_disp_func(void *par);
void task_alloc_func(void *par);

//-------- Semaphores -----------------------

TN_SEM semTxUart;
//GPS
TN_SEM SemISR;
TN_SEM SemMeas;

//------- Queues ----------------------------
#define  QUEUE_TXUART_SIZE      64

//--- UART TX queue
TN_DQUE  queueTxUart;
void     * queueTxUartMem[QUEUE_TXUART_SIZE];

//----------------------------------------------------------------------------
int main(void)
{
  int i;

   tn_arm_disable_interrupts();

   MEMMAP = 0x1;  //-- Flash Build

   HardwareInit();

   //===Takuji Ebinuma code===
   // make reset:
   outpw(RESET, 0);
   //set TIC period:
   outpw(PROG_TIC_LOW,   (7999999L & 0x0000ffff));      // 0.1 sec.
   outpw(PROG_TIC_HIGH, ((7999999L & 0xffff0000)>>16)); // 0.1 sec.

   // Initialize channels
   for (i=0; i<MAX_CHANNELS; i++) {
     CH[i].BASE = 0x26*i;
     CH[i].prn = IDLE;
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
     CH[i].carr_nco = CARR_REF;
     CH[i].code_nco = CODE_REF;
   }
   //===Takuji Ebinuma code - END===

   tn_start_system(); //-- Never returns

   return 1;
}

//----------------------------------------------------------------------------
void  tn_app_init()
{
  //--- Task LED1 blink
  task_led1.id_task = 0;
  tn_task_create(&task_led1,                     //-- task TCB
                task_led1_func,                  //-- task function
                TASK_LED1_PRIORITY,              //-- task priority
                &(task_led1_stack                //-- task stack first addr in memory
                  [TASK_LED1_STK_SIZE-1]),
                TASK_LED1_STK_SIZE,              //-- task stack size (in int,not bytes)
                NULL,                            //-- task function parameter
                TN_TASK_START_ON_CREATION        //-- Creation option
                );

  //--- Task CHECKMEM
  task_checkmem.id_task = 0;
  tn_task_create(&task_checkmem,                 //-- task TCB
                task_checkmem_func,              //-- task function
                TASK_CHECKMEM_PRIORITY,          //-- task priority
                &(task_checkmem_stack            //-- task stack first addr in memory
                   [TASK_CHECKMEM_STK_SIZE-1]),
                TASK_CHECKMEM_STK_SIZE,          //-- task stack size (in int,not bytes)
                NULL,                            //-- task function parameter
                TN_TASK_START_ON_CREATION        //-- Creation option
                );

  //GPS TASKS:
  //--- Task ACCUM
  task_accum.id_task = 0;
  tn_task_create(&task_accum,                    //-- task TCB
                task_accum_func,                 //-- task function
                TASK_ACCUM_PRIORITY,             //-- task priority
                &(task_accum_stack               //-- task stack first addr in memory
                   [TASK_ACCUM_STK_SIZE-1]),
                TASK_ACCUM_STK_SIZE,             //-- task stack size (in int,not bytes)
                NULL,                            //-- task function parameter
                TN_TASK_START_ON_CREATION        //-- Creation option
                );

  //--- Task MEAS
  task_meas.id_task = 0;
  tn_task_create(&task_meas,                     //-- task TCB
                task_meas_func,                  //-- task function
                TASK_MEAS_PRIORITY,              //-- task priority
                &(task_meas_stack                //-- task stack first addr in memory
                   [TASK_MEAS_STK_SIZE-1]),
                TASK_MEAS_STK_SIZE,              //-- task stack size (in int,not bytes)
                NULL,                            //-- task function parameter
                TN_TASK_START_ON_CREATION        //-- Creation option
                );

  //--- Task DISP
  task_disp.id_task = 0;
  tn_task_create(&task_disp,                     //-- task TCB
                task_disp_func,                  //-- task function
                TASK_DISP_PRIORITY,              //-- task priority
                &(task_disp_stack                //-- task stack first addr in memory
                   [TASK_DISP_STK_SIZE-1]),
                TASK_DISP_STK_SIZE,              //-- task stack size (in int,not bytes)
                NULL,                            //-- task function parameter
                TN_TASK_START_ON_CREATION        //-- Creation option
                );

  //--- Task ALLOC
  task_disp.id_task = 0;
  tn_task_create(&task_alloc,                    //-- task TCB
                task_alloc_func,                 //-- task function
                TASK_ALLOC_PRIORITY,             //-- task priority
                &(task_alloc_stack               //-- task stack first addr in memory
                   [TASK_ALLOC_STK_SIZE-1]),
                TASK_ALLOC_STK_SIZE,             //-- task stack size (in int,not bytes)
                NULL,                            //-- task function parameter
                TN_TASK_START_ON_CREATION        //-- Creation option
                );


  //--- Semaphores
  semTxUart.id_sem = 0;
  tn_sem_create(&semTxUart,1,1);
  //GPS
  SemISR.id_sem  = 0;
  tn_sem_create(&SemISR, 1, 1);
  SemMeas.id_sem = 0;
  tn_sem_create(&SemMeas, 1, 1);

  //--- Queues
   queueTxUart.id_dque = 0;
   tn_queue_create(&queueTxUart,           //-- Ptr to already existing TN_DQUE
                      &queueTxUartMem[0],  //-- Ptr to already existing array of void * to store data queue entries.Can be NULL
                      QUEUE_TXUART_SIZE    //-- Capacity of data queue(num entries).Can be 0
                    );



}

//----------------------------------------------------------------------------
void task_led1_func (void *par)
{
  unsigned int Blink = 1;

  while(1){
    if (Blink & 1) Led1On();
    else           Led1Off();

    Blink = Blink ^ 1;

    tn_task_sleep(250); // Sleep 250 ticks.
  }
}

//----------------------------------------------------------------------------
void task_checkmem_func(void * par)
{
  int cnt = 0;
  volatile char buf[192];

  int i;

  volatile unsigned short *Pointer16;
  unsigned short mem_pattern[8] = {0x1111, 0x0000, 0x5555, 0xAAAA,
                                   0xFFFF, 0xCCCC, 0x3333, 0x7777};
  unsigned short mem_pattern_read[8];

  for(;;) {
    Pointer16 = (unsigned short *)(0x80000300);
    for(i=0; i<8; i++){
      *Pointer16 = mem_pattern[i];
      Pointer16++;
    }

    Pointer16 = (unsigned short *)(0x80000310);
    for(i=0; i<8; i++){
      mem_pattern_read[i] = *Pointer16 & 0xffff;
      Pointer16++;
    }

    tn_snprintf((char*)buf,sizeof(buf),"Memory test #%03d results: "
             "%04X %04X %04X %04X %04X %04X %04X %04X    ->    "
             "%04X %04X %04X %04X %04X %04X %04X %04X"
             "\r\n",cnt, mem_pattern[0], mem_pattern[1], mem_pattern[2],
                         mem_pattern[3], mem_pattern[4], mem_pattern[5],
                         mem_pattern[6], mem_pattern[7],
                         mem_pattern_read[0], mem_pattern_read[1], mem_pattern_read[2],
                         mem_pattern_read[3], mem_pattern_read[4], mem_pattern_read[5],
                         mem_pattern_read[6], mem_pattern_read[7]);

      cnt++;

      exs_send_to_uart((unsigned char*)buf);

      tn_task_sleep(2000);

      tn_task_exit(0); // exit task.
   }
}

//----------------------------------------------------------------------------
void task_alloc_func(void *par)
{
  int i,k,already_allocated;
  static int sv = 0;

  while (1) {
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
        CH[i].carr_nco = CARR_REF;
        CH[i].code_nco = CODE_REF;

        outpw((CH[i].BASE+PRN_KEY), prntaps[sv]);
        // Some kind of blocking of process switch should be added!
        outpw((CH[i].BASE+CARR_NCO_LOW),  (CH[i].carr_nco & 0x0000ffff));
        outpw((CH[i].BASE+CARR_NCO_HIGH), ((CH[i].carr_nco & 0xffff0000)>>16));
        // Some kind of blocking of process switch should be added!
        outpw((CH[i].BASE+CODE_NCO_LOW),  (CH[i].code_nco & 0x0000ffff));
        outpw((CH[i].BASE+CODE_NCO_HIGH), ((CH[i].code_nco & 0xffff0000)>>16));

        CH[i].prn = sv+1;

        // Search the next unallocated satellite
        do {
          sv++;
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

    tn_task_sleep(1250); //sleep for 1 sec.
  }
}

//----------------------------------------------------------------------------
void task_disp_func(void *par)
{
  int i;
  double doppler, snr;

  volatile char buf[192];//[Art]

  while (1) {
    for (i=0; i<MAX_CHANNELS; i++) {
      doppler = (double)(CH[i].carr_nco)*NCO_RESOLUTION - 2.42e6;

      snr = 10.0*log10((double)CH[i].pow_code/(double)NoiseFloor);
      if (snr<0.0)
        snr = 0.0;
      //tn_snprintf((char*)buf,sizeof(buf),"%2d %02d %8.1f %5.1f %1d%1d%1d\n",
      tn_snprintf((char*)buf,sizeof(buf),"%02d %02d %05d %03d %1d%1d%1d\r\n",
             i+1, CH[i].prn,
             (int)(doppler), (int)(snr),
             (CH[i].lock_status&PHASE_LOCK)? 1:0,
             (CH[i].lock_status&CARR_LOCK)? 1:0,
             (CH[i].lock_status&CODE_LOCK)? 1:0);

      exs_send_to_uart((unsigned char*)buf);

    }

    tn_task_sleep(1250); //sleep for 1 sec.
  }
}

//----------------------------------------------------------------------------
void task_meas_func(void *par)
{
  unsigned int Blink = 1;

  while (1) {
    tn_sem_acquire(&SemMeas,TN_WAIT_INFINITE);

    // Show that we are alive (blink a LED2)!
    if (Blink & 1) Led2On();
    else           Led2Off();

    Blink = Blink ^ 1;
    // Read measurement registers
    // ....
  }
}

//----------------------------------------------------------------------------
void task_accum_func(void *par)
{
  unsigned short new_data;
  unsigned short current_epoch[MAX_CHANNELS];
  long IP[MAX_CHANNELS],QP[MAX_CHANNELS];
  long IE[MAX_CHANNELS],QE[MAX_CHANNELS];
  long IL[MAX_CHANNELS],QL[MAX_CHANNELS];
  int i;
  unsigned short channel_mask;

  while (1) {
    tn_sem_acquire(&SemISR,TN_WAIT_INFINITE);

    // Check status register for a TIC:
    if (status&0x1)
      tn_sem_signal(&SemMeas);

    // NEW_DATA register shows which channels have new accumulation data available:
    new_data = (unsigned short)inpw(NEW_DATA);

    // Get and store the accumulation data:
    channel_mask = 0x1;

    for (i=0; i<MAX_CHANNELS; i++) {
      if (new_data&channel_mask) {
        current_epoch[i] = (unsigned short)inpw((CH[i].BASE+EPOCH_CHECK));

        IP[i] = (long)(short)inpw((CH[i].BASE+I_PROMPT));
        QP[i] = (long)(short)inpw((CH[i].BASE+Q_PROMPT));
        IE[i] = (long)(short)inpw((CH[i].BASE+I_EARLY));
        QE[i] = (long)(short)inpw((CH[i].BASE+Q_EARLY));
        IL[i] = (long)(short)inpw((CH[i].BASE+I_LATE));
        QL[i] = (long)(short)inpw((CH[i].BASE+Q_LATE));

        // Scale for fixed-point arithmetic:
        IP[i] >>= 2;
        QP[i] >>= 2;
        IE[i] >>= 2;
        QE[i] >>= 2;
        IL[i] >>= 2;
        QL[i] >>= 2;
      }

      channel_mask <<= 1;
    }

    // Update the carrier and code tracking loops:
    channel_mask = 0x1;

    for (i=0; i<MAX_CHANNELS; i++) {
      if (new_data&channel_mask) {
        long pow_code;
        long pow_carr;

        // Get instantaneous signal power:
        pow_code = IP[i]*IP[i] + QP[i]*QP[i];

        if (CH[i].lock_status&CODE_LOCK) {
          // Average noisy signal power:
          CH[i].pow_code += (pow_code - CH[i].pow_code + 128L)>>8;

          // Use inner product for carrier lock indicator:
          pow_carr = IP[i]*CH[i].IP + QP[i]*CH[i].QP;
          CH[i].pow_carr += (pow_carr - CH[i].pow_carr + 128L)>>8;
        }

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

        // If code lock has been achieved then update the tracking loops:
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

          ltemp = -sign(QP[i])*IP[i];
          E = ltemp<<11;
          ltemp = (E - CH[i].E) + ((E + 16L)>>5);
          CH[i].E = E;
          F = QP[i]*CH[i].IP - IP[i]*CH[i].QP;

          delta_carr_nco = -((ltemp + 16384L)>>15) + ((F + 8192L)>>14);

          CH[i].carr_nco += delta_carr_nco;

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
        else { // No code lock:
          // Update the code phase:
          outpw((CH[i].BASE+CODE_SLEW),1);

          // Increment the amount of code searched:
          CH[i].half_chip_counter++;

          if (CH[i].half_chip_counter > 2045) {
            short f_bin;

            // Reset the amount of code searched:
            CH[i].half_chip_counter = 0;

            // Increment the frequency bin:
            CH[i].freq_bin_counter++;

            // Check if all frequency bins have been searched:
            if (CH[i].freq_bin_counter > CarrSrchWidth) {
              CH[i].prn = IDLE;
              CH[i].freq_bin_counter = 0;
            }

            // Get the code and carrier NCO offset:
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

        // Save the current prompt arms:
        CH[i].IP = IP[i];
        CH[i].QP = QP[i];

        // Update the carrier NCO:
        // Some kind of blocking of process switch should be added!
        outpw((CH[i].BASE+CARR_NCO_LOW),  (CH[i].carr_nco & 0x0000ffff));
        outpw((CH[i].BASE+CARR_NCO_HIGH), ((CH[i].carr_nco & 0xffff0000)>>16));

        // Update the code NCO
        // Some kind of blocking of process switch should be added!
        outpw((CH[i].BASE+CODE_NCO_LOW),  (CH[i].code_nco & 0x0000ffff));
        outpw((CH[i].BASE+CODE_NCO_HIGH), ((CH[i].code_nco & 0xffff0000)>>16));
      }

      channel_mask <<= 1;
    }
  }
}

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------



