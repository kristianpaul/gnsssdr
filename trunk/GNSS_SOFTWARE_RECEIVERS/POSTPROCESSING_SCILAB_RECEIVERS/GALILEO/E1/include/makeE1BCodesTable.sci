function E1BCodesTable = makeE1BCodesTable(settings)
//Function generates E1B codes for all 50 satellites based on the settings
//provided in the structure "settings". The codes are digitized at the
//sampling frequency specified in the settings structure.
//One row in the "E1BCodesTable" is one E1B code. The row number is the PRN
//number of the E1B code.
//
//caCodesTable = makeCaTable(settings)
//
//   Inputs:
//       settings        - receiver settings
//   Outputs:
//       caCodesTable    - an array of arrays (matrix) containing E1B codes
//                       for all satellite PRN-s

//--------------------------------------------------------------------------
//                           SoftGNSS v3.0
// 
// Copyright (C) Darius Plausinaitis
// Written by Darius Plausinaitis
// Based on Peter Rinder and Nicolaj Bertelsen
// SciLab Galileo version by Gavrilov Artyom
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

  //--- Find number of samples per spreading code ----------------------------
  samplesPerCode = round(settings.samplingFreq / ...
                           (settings.codeFreqBasis / settings.codeLength));
  
  //--- Prepare the output matrix to speed up function -----------------------
  E1BCodesTable = zeros(settings.NumberOfE1BCodes/2.5, samplesPerCode);
  
  //--- Find time constants --------------------------------------------------
  ts = 1/settings.samplingFreq;   // Sampling period in sec
  tc = 1/settings.codeFreqBasis;  // E1B chip period in sec
  
  //=== For all satellite PRN-s ...
///  for PRN = 1:settings.NumberOfE1BCodes
for PRN = 1:50
    //--- Read E1B code for given PRN -----------------------------------
    E1BCode = readE1Bcode(PRN);
    E1BCode = kron(E1BCode, ones(1,2));
    
    //--- Generate meander:
    meandr = ones(1, settings.codeLength*2);
    meandr(2:2:$) = -1;
    
    E1BCode = E1BCode .* meandr;
    
    //=== Digitizing =======================================================
    
    //--- Make index array to read C/A code values -------------------------
    // The length of the index array depends on the sampling frequency -
    // number of samples per millisecond (because one C/A code period is one
    // millisecond).
    codeValueIndex = ceil((ts * (1:samplesPerCode)) / tc * 2);
    
    //--- Correct the last index (due to number rounding issues) -----------
    codeValueIndex($)  = settings.codeLength;
    
    //--- Make the digitized version of the C/A code -----------------------
    // The "upsampled" code is made by selecting values form the CA code
    // chip array (caCode) for the time instances of each sample.
    E1BCodesTable(PRN, :) = E1BCode(codeValueIndex);
    
  end // for PRN = 1:50
endfunction
