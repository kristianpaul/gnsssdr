function caCodesTable = makeCaTable(settings)
//Function generates CA codes for all 32 satellites based on the settings
//provided in the structure "settings". The codes are digitized at the
//sampling frequency specified in the settings structure.
//One row in the "caCodesTable" is one C/A code. The row number is the PRN
//number of the C/A code.
//
//caCodesTable = makeCaTable(settings)
//
//   Inputs:
//       settings        - receiver settings
//   Outputs:
//       caCodesTable    - an array of arrays (matrix) containing C/A codes
//                       for all satellite PRN-s

//--------------------------------------------------------------------------
//                           SoftGNSS v3.0
// 
// Copyright (C) Darius Plausinaitis
// Written by Darius Plausinaitis
// Based on Peter Rinder and Nicolaj Bertelsen
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

  //--- Find number of samples per spreading code ----------------------------
  samplesPerCode = round(settings.samplingFreq / ...
                             (settings.codeFreqBasis / settings.codeLength));

  //--- Prepare the output matrix to speed up function -----------------------
  caCodesTable = zeros(32, samplesPerCode);

  //--- Find time constants --------------------------------------------------
  ts = 1/settings.samplingFreq;   // Sampling period in sec
  tc = 1/settings.codeFreqBasis;  // C/A chip period in sec

  //=== For all satellite PRN-s ...
  for PRN = 1:32
    //--- Generate CA code for given PRN -----------------------------------
    caCode = generateCAcode(PRN+32); // Generate codes for information channel
 
    //=== Digitizing =======================================================
    
    //--- Make index array to read C/A code values -------------------------
    // The length of the index array depends on the sampling frequency -
    // number of samples per millisecond (because one C/A code period is one
    // millisecond).
    codeValueIndex = ceil((ts * (1:samplesPerCode)) / tc);
    
    //--- Correct the last index (due to number rounding issues) -----------
    codeValueIndex($) = settings.codeLength;
    //--- Make the digitized version of the C/A code -----------------------
    // The "upsampled" code is made by selecting values form the CA code
    // chip array (caCode) for the time instances of each sample.
    caCodesTable(PRN, :) = caCode(codeValueIndex);
  end // for PRN = 1:32
  
endfunction
