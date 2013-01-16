function settings = initSettings()
//Functions initializes and saves settings. Settings can be edited inside of
//the function, updated from the command line or updated using a dedicated
//GUI - "setSettings".  
//
//All settings are described inside function code.
//
//settings = initSettings()
//
//   Inputs: none
//
//   Outputs:
//       settings     - Receiver settings (a structure). 

//--------------------------------------------------------------------------
//                           SoftGNSS v3.0
// 
// Copyright (C) Darius Plausinaitis
// Written by Darius Plausinaitis
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

  // Processing settings ====================================================
  // Number of milliseconds to be processed used 36000 + any transients (see
  // below - in Nav parameters) to ensure nav subframes are provided
  settings.msToProcess        = 14000;        //[ms]

  // Number of channels to be used for signal processing
  settings.numberOfChannels   = 7;

  // Move the starting point of processing. Can be used to start the signal
  // processing at any point in the data record (e.g. for long records). fseek
  // function is used to move the file read point, therefore advance is byte
  // based only. 
  settings.skipNumberOfBytes     = 1*16e6;

  // Raw signal file name and other parameter ===============================
  // This is a "default" name of the data file (signal record) to be used in
  // the post-processing mode
  settings.fileName           = ...
    'E:\COMPASS_B1\New\14.01.2013\FFF005.DAT';

  // Data type used to store one sample
  settings.dataType           = 'cl';

  // File Types
  //1 - 8 bit real samples S0,S1,S2,...
  //2 - 8 bit I/Q samples I0,Q0,I1,Q1,I2,Q2,...                      
  settings.fileType           = 2;

  // Intermediate, sampling and code frequencies
  settings.IF                 = 0.098e6;      //[Hz]
  settings.samplingFreq       = 16.000e6;       //[Hz]
  settings.codeFreqBasis      = 2.046e6;      //[Hz]

  // Define number of chips in a code period
  settings.codeLength         = 2046;

  // Acquisition settings ===================================================
  // Skips acquisition in the script postProcessing.sci if set to 1
  settings.skipAcquisition    = 0;
  // List of satellites to look for. Some satellites can be excluded to speed
  // up acquisition
  settings.acqSatelliteList   = [1:37];       //[PRN numbers]
  // Band around IF to search for satellite signal. Depends on max Doppler
  settings.acqSearchBand      = 14;           //[kHz]
  // Threshold for the signal presence decision rule
  settings.acqThreshold       = 3.0;
  // Coherent integration time during acquisition (for COMPASS it can be from 1 
  // to 10 ms for current acquisition implementation)
  settings.acqCohIntegration  = 3;

  // Tracking loops settings ================================================
  // Code tracking loop parameters
  settings.dllDampingRatio         = 0.7;
  settings.dllNoiseBandwidth       = 1;       //[Hz]
  settings.dllCorrelatorSpacing    = 0.25;       //[chips]

  // Carrier tracking loop parameters
  settings.pllDampingRatio         = 0.7;
  settings.pllNoiseBandwidth       = 40;        //[Hz] //when this parameter is 
                                                //less than 40 - no PLL 
                                                //lock for some sattelites.
  settings.fllNoiseBandwidth       = 200;       //[Hz]

  // Navigation solution settings ===========================================
  
  settings.skipNumberOfFirstBits   = 2500;      // Number of ms to skip (because
                                                // of FLL to PLL transient)

  // Period for calculating pseudoranges and position
  settings.navSolPeriod       = 500;            //[ms]

  // Elevation mask to exclude signals from satellites at low elevation
  settings.elevationMask      = 0;              //[degrees 0 - 90]
  // Enable/dissable use of tropospheric correction
  settings.useTropCorr        = 1;              // 0 - Off
                                                // 1 - On

  // True position of the antenna in UTM system (if known). Otherwise enter
  // all NaN's and mean position will be used as a reference .
  settings.truePosition.E     = %nan;
  settings.truePosition.N     = %nan;
  settings.truePosition.U     = %nan;

  // Plot settings ==========================================================
  // Enable/disable plotting of the tracking results for each channel
  settings.plotTracking       = 1;          // 0 - Off
                                            // 1 - On
  // Constants ==============================================================

  settings.c                  = 299792458;    // The speed of light, [m/s]

endfunction
