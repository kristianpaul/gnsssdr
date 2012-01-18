/*
 * Milkymist SoC (Software)
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
#include "./isrl/isrl.h"


#define PIN_MASK	(1<<7)    // Interrupt signal from correlator comes to this pin.
#define FIO0PIN		(*(volatile unsigned int *)(0x60001000))

#define LED00		(*(volatile unsigned int *)(1610616836))

//======main==========================================================

int main(int i, char **c)
{
	int a1, b1, a2, b2, c1, c2;

	int errors;			//number of errors during memory test.
	unsigned int PIN_STATUS;	//used to check pin_status. Thus emulating interrupt.

	//Some initialization: 
	irq_setmask(0);
	irq_enable(1);
	uart_init();
	
	//Correlator initialization:
	correlator_init();

	//Correlator memory test:
	memory_test();


	LED00=3;
	while ( 1 ) {	//endless cycle in which we always check interrupt request from correlator.

		if (FIO0PIN & 128) gpsisr();		
	}

	return 0;
}
