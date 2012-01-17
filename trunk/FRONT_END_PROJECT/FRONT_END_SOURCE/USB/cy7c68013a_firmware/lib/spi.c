/* -*- c++ -*- */
/*
 * Copyright 2004,2006 Free Software Foundation, Inc.
 * 
 * This file is part of GNU Radio
 * 
 * GNU Radio is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3, or (at your option)
 * any later version.
 * 
 * GNU Radio is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with GNU Radio; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street,
 * Boston, MA 02110-1301, USA.
 */

#include "spi.h"
#include "fx2regs.h"/*Art*/


/*Art*/
static void spi_io2(unsigned char b1, unsigned char b2, unsigned char b3, unsigned char b4) //Function that sends data to slave.
//IOA.1 = clock;
//IOA.2 = DATA;
//IOA.4 = #Enable.
{
	unsigned char i;
	IOA &= ~0x08;
	i = 8;
	do {
		IOA &= ~0x01;				//OFF(SCK);
		IOA &= ~0x02;				//OFF(MOSI);
		if(b1 & 0x80) IOA |= 0x02;	//ON(MOSI);
		b1 <<= 1;					//
		IOA |= 0x01;				//ON(SCK);
	} while(--i);
	IOA &= ~0x01; 					//OFF(SCK);
	i = 8;
	do {
		IOA &= ~0x01;				//OFF(SCK);
		IOA &= ~0x02;				//OFF(MOSI);
		if(b2 & 0x80) IOA |= 0x02;	//ON(MOSI);
		b2 <<= 1;					//
		IOA |= 0x01;				//ON(SCK);
	} while(--i);
	IOA &= ~0x01;
	i = 8;
	do {
		IOA &= ~0x01;				//OFF(SCK);
		IOA &= ~0x02;				//OFF(MOSI);
		if(b3 & 0x80) IOA |= 0x02;	//ON(MOSI);
		b3 <<= 1;					//
		IOA |= 0x01;				//ON(SCK);
	} while(--i);
	IOA &= ~0x01;
	i = 8;
	do {
		IOA &= ~0x01;				//OFF(SCK);
		IOA &= ~0x02;				//OFF(MOSI);
		if(b4 & 0x80) IOA |= 0x02;	//ON(MOSI);
		b4 <<= 1;					//
		IOA |= 0x01;				//ON(SCK);
	} while(--i);
	IOA &= ~0x01;
	IOA = 0x08;
}
/*Art*/
