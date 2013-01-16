function [k1, k2, k3] = calcFLLPLLLoopCoef(pllbw, fllbw, T)
//Function finds FLL-assisted PLL loop coefficients.
//
//[k1, k2, k3] = calcLoopCoefNew(pllbw, fllbw, T)
//
//   Inputs:
//       pllbw  - PLL loop noise bandwidth
//       fllbw  - FLL loop noise bandwidth
//       T      - integration periode
//
//   Outputs:
//       k1, k2, k3    - Loop filter coefficients 
 
//--------------------------------------------------------------------------
//                           SoftGNSS v3.0
// 
// Written in scilab 5.3.0 by Artyom Gavrilov
//--------------------------------------------------------------------------
//This program is free software; you can redistribute it and/or
//modify it under the terms of the GNU General Public License
//as published by the Free Software Foundation; either version 2
//of the License, or (at your option) any later version.
//
//This program is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.
//
//You should have received a copy of the GNU General Public License
//along with this program; if not, write to the Free Software
//Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
//USA.
//--------------------------------------------------------------------------

  
  k1 = T*( (pllbw/0.53)^2 ) + 1.414*(pllbw/0.53);
  k2 = 1.414 * (pllbw/0.53);
  k3 = T * (fllbw/0.25);
  
  //All magic numbers: 0.53; 1.414; 0.25 are taken from Kaplan book: 
  // "Understanding GPS Principles and Applications, Second edition"
  // p.180, table 5.6.

endfunction
