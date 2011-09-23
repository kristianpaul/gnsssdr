/*****************************************************************************
 *   pll.h:  Header file for lpc2478 UART-block.
 *
 *
 *   History
 *   2011.07.01  ver 0.01    Prelimnary version, first Release
 *
******************************************************************************/
#ifndef __UART_H
#define __UART_H

/*****************************************************************************
 * Defines and typedefs
 ****************************************************************************/
extern unsigned int UARTInit( unsigned int PortNum, unsigned int baudrate );
extern int mputchar (int ch);
extern int mgetchar (void);

#endif /* end __UART_H */
/*****************************************************************************
**                            End Of File
******************************************************************************/
