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

  //--- Make the code shift array. The shift depends on the PRN number -------
  // The g2s vector holds the appropriate initial value for g2
  g2s(1,1:7) = -1*[-1 -1 -1 -1 -1 -1  1];//#01
  g2s(2,1:7) = -1*[-1 -1 -1 -1 -1  1 -1];//#02
  g2s(3,1:7) = -1*[-1 -1 -1 -1 -1  1  1];//#03
  g2s(4,1:7) = -1*[-1 -1 -1 -1  1 -1 -1];//#04
  g2s(5,1:7) = -1*[-1 -1 -1 -1  1 -1  1];//#05
  g2s(6,1:7) = -1*[-1 -1 -1 -1  1  1 -1];//#06
  g2s(7,1:7) = -1*[-1 -1 -1 -1  1  1  1];//#07
  g2s(8,1:7) = -1*[-1 -1 -1  1 -1 -1 -1];//#08
  g2s(9,1:7) = -1*[-1 -1 -1  1 -1 -1  1];//#09
  g2s(10,1:7) = -1*[-1 -1 -1  1 -1  1 -1];//#10
  g2s(11,1:7) = -1*[-1 -1 -1  1 -1  1  1];//#11
  g2s(12,1:7) = -1*[-1 -1 -1  1  1 -1 -1];//#12
  g2s(13,1:7) = -1*[-1 -1 -1  1  1 -1  1];//#13
  g2s(14,1:7) = -1*[-1 -1 -1  1  1  1 -1];//#14
  g2s(15,1:7) = -1*[-1 -1 -1  1  1  1  1];//#15
  g2s(16,1:7) = -1*[-1 -1  1 -1 -1 -1 -1];//#16
  g2s(17,1:7) = -1*[-1 -1  1 -1 -1 -1  1];//#17
  g2s(18,1:7) = -1*[-1 -1  1 -1 -1  1 -1];//#18
  g2s(19,1:7) = -1*[-1 -1  1 -1 -1  1  1];//#19
  g2s(20,1:7) = -1*[-1 -1  1 -1  1 -1 -1];//#20
  g2s(21,1:7) = -1*[-1 -1  1 -1  1 -1  1];//#21
  g2s(22,1:7) = -1*[-1 -1  1 -1  1  1 -1];//#22
  g2s(23,1:7) = -1*[-1 -1  1 -1  1  1  1];//#23
  g2s(24,1:7) = -1*[-1 -1  1  1 -1 -1 -1];//#24
  g2s(25,1:7) = -1*[-1 -1  1  1 -1 -1  1];//#25
  g2s(26,1:7) = -1*[-1 -1  1  1 -1  1 -1];//#26
  g2s(27,1:7) = -1*[-1 -1  1  1 -1  1  1];//#27
  g2s(28,1:7) = -1*[-1 -1  1  1  1 -1 -1];//#28
  g2s(29,1:7) = -1*[-1 -1  1  1  1 -1  1];//#29
  g2s(30,1:7) = -1*[-1 -1  1  1  1  1 -1];//#30
  g2s(31,1:7) = -1*[-1 -1  1  1  1  1  1];//#31
  
  g2s(31,1:7) = -1*[-1  1 -1 -1 -1 -1 -1];//#32
  
  g2s(33,1:7) = -1*[-1  1 -1 -1 -1 -1  1];//#33
  g2s(34,1:7) = -1*[-1  1 -1 -1 -1  1 -1];//#34
  g2s(35,1:7) = -1*[-1  1 -1 -1 -1  1  1];//#35
  g2s(36,1:7) = -1*[-1  1 -1 -1  1 -1 -1];//#36
  g2s(37,1:7) = -1*[-1  1 -1 -1  1 -1  1];//#37
  g2s(38,1:7) = -1*[-1  1 -1 -1  1  1 -1];//#38
  g2s(39,1:7) = -1*[-1  1 -1 -1  1  1  1];//#39
  g2s(40,1:7) = -1*[-1  1 -1  1 -1 -1 -1];//#40
  g2s(41,1:7) = -1*[-1  1 -1  1 -1 -1  1];//#41
  g2s(42,1:7) = -1*[-1  1 -1  1 -1  1 -1];//#42
  g2s(43,1:7) = -1*[-1  1 -1  1 -1  1  1];//#43
  g2s(44,1:7) = -1*[-1  1 -1  1  1 -1 -1];//#44
  g2s(45,1:7) = -1*[-1  1 -1  1  1 -1  1];//#45
  g2s(46,1:7) = -1*[-1  1 -1  1  1  1 -1];//#46
  g2s(47,1:7) = -1*[-1  1 -1  1  1  1  1];//#47
  g2s(48,1:7) = -1*[-1  1  1 -1 -1 -1 -1];//#48
  g2s(49,1:7) = -1*[-1  1  1 -1 -1 -1  1];//#49
  g2s(50,1:7) = -1*[-1  1  1 -1 -1  1 -1];//#50
  g2s(51,1:7) = -1*[-1  1  1 -1 -1  1  1];//#51
  g2s(52,1:7) = -1*[-1  1  1 -1  1 -1 -1];//#52
  g2s(53,1:7) = -1*[-1  1  1 -1  1 -1  1];//#53
  g2s(54,1:7) = -1*[-1  1  1 -1  1  1 -1];//#54
  g2s(55,1:7) = -1*[-1  1  1 -1  1  1  1];//#55
  g2s(56,1:7) = -1*[-1  1  1  1 -1 -1 -1];//#56
  g2s(57,1:7) = -1*[-1  1  1  1 -1 -1  1];//#57
  g2s(58,1:7) = -1*[-1  1  1  1 -1  1 -1];//#58
  g2s(59,1:7) = -1*[-1  1  1  1 -1  1  1];//#59
  g2s(60,1:7) = -1*[-1  1  1  1  1 -1 -1];//#60
  g2s(61,1:7) = -1*[-1  1  1  1  1 -1  1];//#61
  g2s(62,1:7) = -1*[-1  1  1  1  1  1 -1];//#62
  g2s(63,1:7) = -1*[-1  1  1  1  1  1  1];//#63
  g2s(64,1:7) = -1*[-1  1  1  1  1  1  1];//#63 Some dirty tricks :(

  //--- Generate G1 code -----------------------------------------------------

  //--- Initialize g1 output to speed up the function ---
  g1 = zeros(1, 10230);
  //--- Load shift register ---
  reg = -1*[-1 -1 1 1 -1 1 -1 -1 1 1 1 -1 -1 -1];

  //--- Generate all G1 signal chips based on the G1 feedback polynomial -----
  for i=1:10230
    g1(i)       = reg(14);
    saveBit     = reg(4)*reg(8)*reg(13)*reg(14);
    reg(2:14)   = reg(1:13);
    reg(1)      = saveBit;
  end

  //--- Generate G2 code -----------------------------------------------------

  //--- Initialize g2 output to speed up the function ---
  g2 = zeros(1, 10230);
  //--- Load shift register ---
  reg2 = g2s(PRN, 1:7);
  //reg2 = flipdim(reg2, 2);

  //--- Generate all G2 signal chips based on the G2 feedback polynomial -----
  for i=1:10230
    g2(i)       = reg2(7);
    saveBit     = reg2(6)*reg2(7);
    reg2(2:7)   = reg2(1:6);
    reg2(1)      = saveBit;
  end
  
  //--- Form single sample C/A code by multiplying G1 and G2 -----------------
  CAcode = -(g1 .* g2);
  
endfunction
