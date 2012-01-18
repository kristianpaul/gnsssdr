/*
 * Milkymist SoC (Software)
 * Copyright (C) 2007, 2008, 2009, 2010 Sebastien Bourdeauducq
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

#ifndef __HW_INTERRUPTS_H
#define __HW_INTERRUPTS_H

#define IRQ_UART		(0x00000001) /* 0 */
#define IRQ_GPIO		(0x00000002) /* 1 */
#define IRQ_TIMER0		(0x00000004) /* 2 */
#define IRQ_TIMER1		(0x00000008) /* 3 */
#define IRQ_ETHRX		(0x00000400) /* 10 */
#define IRQ_ETHTX		(0x00000800) /* 11 */
// TODO: Add namuru IRQ!

#endif /* __HW_INTERRUPTS_H */
