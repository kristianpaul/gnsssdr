/*
 * Milkymist VJ SoC (Software)
 * Copyright (C) 2007, 2008, 2009, 2010, 2011 Sebastien Bourdeauducq
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <stdio.h>
#include <console.h>
#include <string.h>
#include <uart.h>
#include <irq.h>
#include <hw/fmlbrg.h>
#include "./correlator/correlator.h"


#define PIN_MASK	(1<<7)    // Interrupt signal from correlator come to this pin.
#define FIO0PIN 	(*(volatile unsigned int *)(0x60001000))

#define LED00         (*(volatile unsigned int *)(1610616836))

//======main==========================================================

int main(int i, char **c)
{
	int errors;	//number of errors during memory test.
	unsigned int PIN_STATUS;      //used to check pin_status. Thus emulating interrupt.

//	int ie, qe, ip, qp, il, ql;
	int cntr01;
	int led01;

	//Some initialization: 
	irq_setmask(0);
	irq_enable(1);
	uart_init();
	
	//Hello world example:
	printf( "================== TEST =================\n");

	//My experiments with on-board text-lcd:
	lcd_Init();
	lcd_Clear();
	lcd_PrintString("Milkymist v 7.8", "S3E Starterkit");


	//Correlator initialization:
	correlator_init();

	//Correlator memory test:
	memory_test();

	cntr01=0;
	led01 = 1;
	LED00=3;
	while ( 1 ) {	//endless cycle in which we always check interrupt request from correlator.

//		if (FIO0PIN==144) LED00 = 3; else LED00=0;

//		if (FIO0PIN & 128){
//			cntr01++;
//			if ( (cntr01 % 100000) == 0 ){
//				if (led01) led01 = led01 & 4294967294; else led01= led01 | 1;
//				//LED00 = led01;
//			}

//			gpsisr();
			//printf("interrupt!\n");
			//clear_status();
//			printf("Ie = %d\t Qe = %d\t Ip = %d\t Qp = %d\t Il = %d\t Ql = %d\t\n", CORR_ch0_i_early, CORR_ch0_q_early, CORR_ch0_i_prompt, CORR_ch0_q_prompt, CORR_ch0_i_late, CORR_ch0_q_late);
		}
		//else//{
//			printf(".");
//		}

		if(CORR_status>2){
			//printf("status = %d\n", stts);
			clear_status();
			gpsisr();
		}
		

	}

	printf("exit");


	while(1) {
	}
	return 0;
}
