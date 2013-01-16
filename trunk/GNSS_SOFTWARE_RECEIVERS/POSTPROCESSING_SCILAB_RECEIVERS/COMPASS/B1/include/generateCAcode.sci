function CAcode = generateCAcode(PRN)
// generateCAcode.m generates one of the 31 GLONASS satellite CDMA codes.
//
// CAcode = generateCAcode(PRN)
//
//   Inputs:
//       PRN         - PRN number of the sequence.
//
//   Outputs:
//       CAcode      - a vector containing the desired C/A code sequence 
//                   (chips).  

//--------------------------------------------------------------------------
//                           SoftGNSS v3.0
// 
// Copyright (C) Darius Plausinaitis
// Written by Artyom Gavrilov
// Based on Darius Plausinaitis,  Dennis M. Akos, Peter Rinder and 
// Nicolaj Bertelsen
// Updated and converted to scilab 5.3.0 by Artyom Gavrilov
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

  //--- Generate G1 code -----------------------------------------------------

  //--- Initialize g1 output to speed up the function ---
  g1 = zeros(1, 2046);
  //--- Load shift register ---
  reg = -1*[-1 1 -1 1 -1 1 -1 1 -1 1 -1];

  //--- Generate all G1 signal chips based on the G1 feedback polynomial -----
  for i=1:2046
    g1(i)       = reg(11);
    saveBit     = reg(1)*reg(7)*reg(8)*reg(9)*reg(10)*reg(11);
    reg(2:11)   = reg(1:10);
    reg(1)      = saveBit;
  end

  //--- Generate G2 code -----------------------------------------------------

  //--- Initialize g2 output to speed up the function ---
  g2 = zeros(1, 2046);
  //--- Load shift register ---
  reg2 = -1*[-1 1 -1 1 -1 1 -1 1 -1 1 -1];

  //--- Generate all G2 signal chips based on the G2 feedback polynomial -----
  for i=1:2046
    
    if     PRN == 1  then
      g2(i) = reg2(1)*reg2(3);
    elseif PRN == 2 then
      g2(i) = reg2(1)*reg2(4);
    elseif PRN == 3 then
      g2(i) = reg2(1)*reg2(5);
    elseif PRN == 4 then
      g2(i) = reg2(1)*reg2(6);
    elseif PRN == 5 then
      g2(i) = reg2(1)*reg2(8);
    elseif PRN == 6  then
      g2(i) = reg2(1)*reg2(9);
    elseif PRN == 7 then
      g2(i) = reg2(1)*reg2(10);
    elseif PRN == 8 then
      g2(i) = reg2(1)*reg2(11);
    elseif PRN == 9 then
      g2(i) = reg2(2)*reg2(7);
    elseif PRN == 10 then
      g2(i) = reg2(3)*reg2(4);
    elseif PRN == 11 then
      g2(i) = reg2(3)*reg2(5);
    elseif PRN == 12 then
      g2(i) = reg2(3)*reg2(6);
    elseif PRN == 13 then
      g2(i) = reg2(3)*reg2(8);
    elseif PRN == 14 then
      g2(i) = reg2(3)*reg2(9);
    elseif PRN == 15 then
      g2(i) = reg2(3)*reg2(10);
    elseif PRN == 16 then
      g2(i) = reg2(3)*reg2(11);
    elseif PRN == 17 then
      g2(i) = reg2(4)*reg2(5);
    elseif PRN == 18 then
      g2(i) = reg2(4)*reg2(6);
    elseif PRN == 19 then
      g2(i) = reg2(4)*reg2(8);
    elseif PRN == 20 then
      g2(i) = reg2(4)*reg2(9);
    elseif PRN == 21 then
      g2(i) = reg2(4)*reg2(10);
    elseif PRN == 22 then
      g2(i) = reg2(4)*reg2(11);
    elseif PRN == 23 then
      g2(i) = reg2(5)*reg2(6);
    elseif PRN == 24 then
      g2(i) = reg2(5)*reg2(8);
    elseif PRN == 25 then
      g2(i) = reg2(5)*reg2(9);
    elseif PRN == 26 then
      g2(i) = reg2(5)*reg2(10);
    elseif PRN == 27 then
      g2(i) = reg2(5)*reg2(11);
    elseif PRN == 28 then
      g2(i) = reg2(6)*reg2(8);
    elseif PRN == 29 then
      g2(i) = reg2(6)*reg2(9);
    elseif PRN == 30 then
      g2(i) = reg2(6)*reg2(10);
    elseif PRN == 31 then
      g2(i) = reg2(6)*reg2(11);
    elseif PRN == 32 then
      g2(i) = reg2(8)*reg2(9);
    elseif PRN == 33 then
      g2(i) = reg2(8)*reg2(10);
    elseif PRN == 34 then
      g2(i) = reg2(8)*reg2(11);
    elseif PRN == 35 then
      g2(i) = reg2(9)*reg2(10);
    elseif PRN == 36 then
      g2(i) = reg2(9)*reg2(11);
    elseif PRN == 37 then
      g2(i) = reg2(10)*reg2(11);
      
    end
    
    saveBit     = reg2(1)*reg2(2)*reg2(3)*reg2(4)*reg2(5)*reg2(8)*reg2(9)*reg2(11);
    reg2(2:11)   = reg2(1:10);
    reg2(1)      = saveBit;
  end
  
  //--- Form single sample C/A code by multiplying G1 and G2 -----------------
  CAcode = -(g1 .* g2);
  
endfunction
