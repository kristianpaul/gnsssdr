/****************************************************************************
* uart.c
*
*  Created on: 30.05.2011
*      Author: Gavrilov Artyom
****************************************************************************
*  History:
*
*  30.05.11  mifi   First Version.
****************************************************************************/

#include "LPC23xx.h"

#define FPCLK                   18000000  //72MHz / 4 = 18 MHz;
/*****************************************************************************
** Function name:               UARTInit
**
** Descriptions:                Initialize UART0 port, setup pin select,
**                                              clock, parity, stop bits, FIFO, etc.
**
** parameters:                  portNum(0 or 1) and UART baudrate
** Returned value:              true or false, return false only if the
**                                              interrupt handler can't be installed to the
**                                              VIC table
**
*****************************************************************************/
int UARTInit(int PortNum, int baudrate)
{
  int Fdiv;

  if ( PortNum == 0 ) {
    PINSEL0 = 0x00000050;               /* RxD0 and TxD0 */

    U0LCR = 0x83;                       /* 8 bits, no Parity, 1 Stop bit */
    Fdiv = ( FPCLK / 16 ) / baudrate ;  /*baud rate */
    U0DLM = Fdiv / 256;
    U0DLL = Fdiv % 256;
    U0LCR = 0x03;                       /* DLAB = 0 */
    U0FCR = 0x07;                       /* Enable and reset TX and RX FIFO. */

    return (1);
  }
  else
    return (0);
}

/*****************************************************************************
** Function name:               UARTSend
**
** Descriptions:                Write character to Serial Port
**
** parameters:                  char (symbol to write)
** Returned value:
**
*****************************************************************************/
int mputchar (int ch)
{
  if (ch == '\n'){
    while (!(U0LSR & 0x20));
    U0THR = 0x0D; /* output CR */
  }

  while (!(U0LSR & 0x20));

  return (U0THR = ch);
}

/*****************************************************************************
** Function name:               UARTSend
**
** Descriptions:                Read character from Serial Port
**
** parameters:                  char (symbol to write)
** Returned value:              Read char from UART.
**
*****************************************************************************/
int mgetchar (void)
{
  while (!(U0LSR & 0x01));

  return (U0RBR);
}
/*** EOF ***/
