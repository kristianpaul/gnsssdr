function acqResults = acquisition_7x3ms(longSignal, settings)
//Function performs cold start acquisition on the collected "data". It
//searches for COMPASS signals of all satellites, which are listed in field
//"acqSatelliteList" in the settings structure. Function saves code phase
//and frequency of the detected signals in the "acqResults" structure.
//
//acqResults = acquisition(longSignal, settings)
//
//   Inputs:
//       longSignal    - 11 ms of raw signal from the front-end 
//       settings      - Receiver settings. Provides information about
//                       sampling and intermediate frequencies and other
//                       parameters including the list of the satellites to
//                       be acquired.
//   Outputs:
//       acqResults    - Function saves code phases and frequencies of the 
//                       detected signals in the "acqResults" structure. The
//                       field "carrFreq" is set to 0 if the signal is not
//                       detected for the given PRN number. 
 
//--------------------------------------------------------------------------
//                           SoftGNSS v3.0 GLONASS version
// 
// Copyright (C) Darius Plausinaitis and Dennis M. Akos
// Written by Darius Plausinaitis and Dennis M. Akos
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

// Initialization =========================================================

  // Find number of samples per spreading code
  samplesPerCode = round(settings.samplingFreq / ...
                        (settings.codeFreqBasis / settings.codeLength));
  
  //Let's test simple acceleration. Let's resample the signal to lower frequency.
  longSignal = matrix(longSignal, settings.acqResampleCoef, ..
                      length(longSignal) / settings.acqResampleCoef);
  longSignal = sum(longSignal, 'r');
  samplesPerCode = samplesPerCode / settings.acqResampleCoef;

  // Create two "settings.acqCohIntegration" msec vectors of data
  // to correlate with:
  signal1 = longSignal(0*3*samplesPerCode+1:3*samplesPerCode+1*3*samplesPerCode);
  signal2 = longSignal(1*3*samplesPerCode+1:3*samplesPerCode+2*3*samplesPerCode);
  signal3 = longSignal(2*3*samplesPerCode+1:3*samplesPerCode+3*3*samplesPerCode);
  signal4 = longSignal(3*3*samplesPerCode+1:3*samplesPerCode+4*3*samplesPerCode);
  signal5 = longSignal(4*3*samplesPerCode+1:3*samplesPerCode+5*3*samplesPerCode);
  signal6 = longSignal(5*3*samplesPerCode+1:3*samplesPerCode+6*3*samplesPerCode);
  signal7 = longSignal(6*3*samplesPerCode+1:3*samplesPerCode+7*3*samplesPerCode);
  
  // Find sampling period:
  ts = settings.acqResampleCoef / settings.samplingFreq;
  
  // Find phase points of the local carrier wave:
  phasePoints = (0 : (6*samplesPerCode-1)) * 2*%pi*ts;

  // Number of the frequency bins for the given acquisition band 
  numberOfFrqBins = round(settings.acqSearchBand * 2*3) + 1;

  // Generate all C/A codes and sample them according to the sampling freq:
  caCodesTable = makeCaTable(settings);
  
  //--- Initialize arrays to speed up the code -------------------------------
  // Search results of all frequency bins and code shifts (for one satellite)
  results     = zeros(numberOfFrqBins, 21*samplesPerCode);
  // Carrier frequencies of the frequency bins
  frqBins     = zeros(1, numberOfFrqBins);
  
//--- Initialize acqResults ------------------------------------------------
  // Carrier frequencies of detected signals
  acqResults.carrFreq     = zeros(1, 37);
  // C/A code phases of detected signals
  acqResults.codePhase    = zeros(1, 37);
  // Correlation peak ratios of the detected signals
  acqResults.peakMetric   = zeros(1, 37);
  
  printf('(');
  
  // Perform search for all listed PRN numbers ...
  for PRN = settings.acqSatelliteList
  
  // Correlate signals ======================================================   
    //--- Perform DFT of C/A code ------------------------------------------
    //Multiply C/A code on Neumann-Hoffman code (first 5 ms - otherwise too long wait time)
    //NH = "0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 0, 1, 0, 1,  0,  0,  1,  1,  1,  0";
    caCodeFreqDom = conj(fft([-1*caCodesTable(PRN, :) -1*caCodesTable(PRN, :) ..
                              -1*caCodesTable(PRN, :) ..
                              zeros(1, 3*samplesPerCode)]));

    //--- Make the correlation for whole frequency band (for all freq. bins)
    for frqBinIndex = 1:numberOfFrqBins
      //--- Generate carrier wave frequency grid (freqency step depends
      // on "settings.acqCohIntegration") --------------------------------
      frqBins(frqBinIndex) = settings.IF - ...
                             (settings.acqSearchBand/2) * 1000 + ...
                             (1000 / (2*3)) * (frqBinIndex - 1);
      //--- Generate local sine and cosine -------------------------------
      sigCarr = exp(%i*frqBins(frqBinIndex) * phasePoints);
      
      //--- "Remove carrier" from the signal and Convert the baseband 
      // signal to frequency domain --------------------------------------
      //pause;
      IQfreqDom1 = fft(sigCarr .* signal1);
      IQfreqDom2 = fft(sigCarr .* signal2);
      IQfreqDom3 = fft(sigCarr .* signal3);
      IQfreqDom4 = fft(sigCarr .* signal4);
      IQfreqDom5 = fft(sigCarr .* signal5);
      IQfreqDom6 = fft(sigCarr .* signal6);
      IQfreqDom7 = fft(sigCarr .* signal7);
      //pause;
      //--- Multiplication in the frequency domain (correlation in time domain)
      convCodeIQ1 = IQfreqDom1 .* caCodeFreqDom;
      convCodeIQ2 = IQfreqDom2 .* caCodeFreqDom;
      convCodeIQ3 = IQfreqDom3 .* caCodeFreqDom;
      convCodeIQ4 = IQfreqDom4 .* caCodeFreqDom;
      convCodeIQ5 = IQfreqDom5 .* caCodeFreqDom;
      convCodeIQ6 = IQfreqDom6 .* caCodeFreqDom;
      convCodeIQ7 = IQfreqDom7 .* caCodeFreqDom;

      //--- Perform inverse DFT and store correlation results ------------
      acqRes1 = abs(ifft(convCodeIQ1)) .^ 2;
      acqRes2 = abs(ifft(convCodeIQ2)) .^ 2;
      acqRes3 = abs(ifft(convCodeIQ3)) .^ 2;
      acqRes4 = abs(ifft(convCodeIQ4)) .^ 2;
      acqRes5 = abs(ifft(convCodeIQ5)) .^ 2;
      acqRes6 = abs(ifft(convCodeIQ6)) .^ 2;
      acqRes7 = abs(ifft(convCodeIQ7)) .^ 2;
      
      //--- Check which msec had the greater power and save that, will
      //"blend" 1st and 2nd "settings.acqCohIntegration" msec but will
      // correct data bit issues
      results(frqBinIndex, :) = [acqRes1(1:3*samplesPerCode) ..
                                 acqRes2(1:3*samplesPerCode) ..
                                 acqRes3(1:3*samplesPerCode) ..
                                 acqRes4(1:3*samplesPerCode) ..
                                 acqRes5(1:3*samplesPerCode) ..
                                 acqRes6(1:3*samplesPerCode) ..
                                 acqRes7(1:3*samplesPerCode)];
      
    end // frqBinIndex = 1:numberOfFrqBins

// Look for correlation peaks in the results ==============================
    // Find the highest peak and compare it to the second highest peak
    // The second peak is chosen not closer than 1 chip to the highest peak
    
    //--- Find the correlation peak and the carrier frequency --------------
    [peakSize frequencyBinIndex] = max(max(results, 'c'));

    //--- Find code phase of the same correlation peak ---------------------
    [peakSize codePhase] = max(max(results, 'r'));

    //--- Find 1 chip wide CA code phase exclude range around the peak ----
    samplesPerCodeChip   = round(settings.samplingFreq / ..
                                 settings.acqResampleCoef / ..
                                 settings.codeFreqBasis);
    excludeRangeIndex1 = codePhase - samplesPerCodeChip;
    excludeRangeIndex2 = codePhase + samplesPerCodeChip;

    //--- Correct C/A code phase exclude range if the range includes array
    //boundaries
    if excludeRangeIndex1 < 2
        codePhaseRange = excludeRangeIndex2 : ...
                         (samplesPerCode + excludeRangeIndex1);
    elseif excludeRangeIndex2 > samplesPerCode
        codePhaseRange = (excludeRangeIndex2 - samplesPerCode) : ...
                         excludeRangeIndex1;
    else
        codePhaseRange = [1:excludeRangeIndex1, ...
                          excludeRangeIndex2 : samplesPerCode];
    end
    
    //--- Find the second highest correlation peak in the same freq. bin ---
    secondPeakSize = max(results(frequencyBinIndex, codePhaseRange));

    //--- Store result -----------------------------------------------------
    acqResults.peakMetric(PRN) = peakSize/secondPeakSize;
    
    // If the result is above threshold, then there is a signal ...
    if (peakSize/secondPeakSize) > settings.acqThreshold
      //--- Indicate PRN number of the detected signal -------------------
      printf('%02d ', PRN);
      acqResults.codePhase(PRN) = (codePhase-1) * settings.acqResampleCoef;
      acqResults.carrFreq(PRN)    =...
                               settings.IF - ...
                               (settings.acqSearchBand/2) * 1000 + ...
                               (1000 / (2*3)) * (frequencyBinIndex - 1);
        
    else
      //--- No signal with this PRN --------------------------------------
      printf('. ');
    end   // if (peakSize/secondPeakSize) > settings.acqThreshold
    
end    // for PRN = satelliteList

//=== Acquisition is over ==================================================
printf(')\n');

endfunction
