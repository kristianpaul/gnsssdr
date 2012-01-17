function STcode = generateSTcode()
// generateSTcode.m generates GLONASS ST-code (M-sequence).
//
// STcode = generateSTcode()
//
//   Inputs:
//       None.
//
//   Outputs:
//       STcode      - a vector containing the desired ST code sequence 
//                   (chips).
  
//--------------------------------------------------------------------------
//                           SoftGNSS v3.0
// 
// Copyright (C) Darius Plausinaitis
// Written for scilab 5.3.0 by Artyom Gavrilov
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
  
  reg = -1*ones(1,9);
  for i=1:511
    g3(i)=reg(7);
    msave=reg(5)*reg(9);
    reg(2:9)=reg(1:8);
    reg(1)=msave;
  end;
  STcode=-g3'; 
  
endfunction
