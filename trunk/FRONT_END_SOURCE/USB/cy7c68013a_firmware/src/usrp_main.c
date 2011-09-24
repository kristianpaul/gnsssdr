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

#include "usrp_common.h"
#include "usrp_commands.h"
#include "isr.h"
#include "usb_common.h"
#include "fx2utils.h"
#include <string.h>
//#include "eeprom_io.h"
#include "usb_descriptors.h"

#include "spi.h"
#include "fx2regs.h"/*Art*/

#define	bRequestType	SETUPDAT[0]
#define	bRequest		SETUPDAT[1]
#define	wValueL			SETUPDAT[2]
#define	wValueH			SETUPDAT[3]
#define	wIndexL			SETUPDAT[4]
#define	wIndexH			SETUPDAT[5]
#define	wLengthL		SETUPDAT[6]
#define	wLengthH		SETUPDAT[7]


static void
get_ep0_data (void)
{
  EP0BCL = 0;			// arm EP0 for OUT xfer.  This sets the busy bit

  while (EP0CS & bmEPBUSY)	// wait for busy to clear
    ;
}

/*
 * Handle our "Vendor Extension" commands on endpoint 0.
 * If we handle this one, return non-zero.
 */
unsigned char
app_vendor_cmd (void)
{
	
  if (bRequestType == VRT_VENDOR_IN){

    /////////////////////////////////
    //    handle the IN requests
    /////////////////////////////////

    switch (bRequest){

    default:
      return 0;
    }
  }

  else if (bRequestType == VRT_VENDOR_OUT){

    /////////////////////////////////
    //    handle the OUT requests
    /////////////////////////////////

    switch (bRequest){

    case VRQ_PROGRAM_MAX2769:
      OEA = 0x0B;
      IOA = 0x08;
      
      get_ep0_data ();
      spi_io2(EP0BUF[0], EP0BUF[1], EP0BUF[2], EP0BUF[3]);
      EP0BCL;
      
      break;
    
    default:
      return 0;
    }

  }
  else
    return 0;    // invalid bRequestType

  return 1;
}



static void
main_loop (void)
{
  while (1){

    if (usb_setup_packet_avail ())
      usb_handle_setup_packet ();

  }
}


void
main (void)
{
  init_usrp ();
  
  EA = 0;		// disable all interrupts

  setup_autovectors ();
  usb_install_handlers ();

  EIEX4 = 0;
  EA = 1;		// global interrupt enable

  fx2_renumerate ();	// simulates disconnect / reconnect

  main_loop ();
}
