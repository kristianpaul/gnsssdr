/* 
 * USRP - Universal Software Radio Peripheral
 *
 * Copyright (C) 2003,2004 Free Software Foundation, Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Boston, MA  02110-1301  USA
 */

#ifndef _USRP_COMMANDS_H_
#define _USRP_COMMANDS_H_

#include <usrp_interfaces.h>

#define	MAX_EP0_PKTSIZE		       64	// max size of EP0 packet on FX2

// ----------------------------------------------------------------
//			Vendor bmRequestType's
// ----------------------------------------------------------------

#define	VRT_VENDOR_IN			0xC0
#define	VRT_VENDOR_OUT			0x40

// ----------------------------------------------------------------
//			  USRP Vendor Requests
//
// Note that Cypress reserves [0xA0,0xAF].
// 0xA0 is the firmware load function.
// ----------------------------------------------------------------


// IN commands

//Art!#define	VRQ_I2C_READ			0x81		// wValueL: i2c address; length: how much to read

// OUT commands

#define	VRQ_PROGRAM_MAX2769			0x0C	//FX2LP accepts 4 bytes (1 control word) from PC and sends them to MAX2769.


#endif _USRP_COMMANDS_H_
