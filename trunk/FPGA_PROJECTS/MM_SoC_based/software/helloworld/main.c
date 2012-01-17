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

int main(int i, char **c)
{
	int k;

	irq_setmask(0);
	irq_enable(1);
	uart_init();

	printf("\n\n\n\nHello World!\n\n\n\n");

	//for(k=0; k<10; k++){
	//	printf("k = %d\n", k);
	//}

	while(1) {
		k++;
		if ((k%10000)==0)
			printf("k = %d\n", k);
	}
	return 0;
}
