// Script postProcessing.m processes the raw signal from the specified data
// file (in settings) operating on blocks of 37 seconds of data.
//
// First it runs acquisition code identifying the satellites in the file,
// then the code and carrier for each of the satellites are tracked, storing
// the 1msec accumulations.  After processing all satellites in the 37 sec
// data block, then postNavigation is called. It calculates pseudoranges
// and attempts a position solutions. At the end plots are made for that
// block of data.

//--------------------------------------------------------------------------
//                           SoftGNSS v3.0 GLONASS version
// 
// Copyright (C) Darius Plausinaitis
// Written by Darius Plausinaitis, Dennis M. Akos
// Some ideas by Dennis M. Akos
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

//                         THE SCRIPT "RECIPE"
//
// The purpose of this script is to combine all parts of the software
// receiver.
//
// 1.1) Open the data file for the processing and seek to desired point.
//
// 2.1) Acquire satellites
//
// 3.1) Initialize channels (preRun.m).
// 3.2) Pass the channel structure and the file identifier to the tracking
// function. It will read and process the data. The tracking results are
// stored in the trackResults structure. The results can be accessed this
// way (the results are stored each millisecond):
// trackResults(channelNumber).XXX(fromMillisecond : toMillisecond), where
// XXX is a field name of the result (e.g. I_P, codePhase etc.)
//
// 4) Pass tracking results to the navigation solution function. It will
// decode navigation messages, find satellite positions, measure
// pseudoranges and find receiver position.
//
// 5) Plot the results.

// Initialization =========================================================
disp ('Starting processing...');

[fid, message] = mopen(settings.fileName, 'rb');

//Initialize the multiplier to adjust for the data type
if (settings.fileType==1) 
  dataAdaptCoeff=1;
else
  dataAdaptCoeff=2;
end

//If success, then process the data
if (fid > 0)
  
  // Move the starting point of processing. Can be used to start the
  // signal processing at any point in the data record (e.g. good for long
  // records or for signal processing in blocks).
  mseek(dataAdaptCoeff*settings.skipNumberOfBytes, fid); 
  
// Acquisition ============================================================
  
  // Do acquisition if it is not disabled in settings or if the variable
  // acqResults does not exist.
  if ((settings.skipAcquisition == 0) | ~exists('acqResults'))
    
    // Find number of samples per spreading code
    samplesPerCode = round(settings.samplingFreq / ...
                          (settings.codeFreqBasis / settings.codeLength));
    
    // Read data for acquisition. 11ms of signal are needed for the fine
    // frequency estimation
    
    data  = mget(dataAdaptCoeff*25*samplesPerCode, settings.dataType, fid);
    
    if (dataAdaptCoeff==2)
      data1=data(1:2:$);
      data2=data(2:2:$);
      if (settings.switchIQ == 1)
        data=data2 + %i.*data1;
      else
        data=data1 + %i.*data2;
      end
    end
    
    //--- Do the acquisition -------------------------------------------
    printf('   Acquiring satellites...\n');
    
    if (settings.acqMode == 3)
      acqResults = acquisition_7x3ms(data, settings);
    elseif (settings.acqMode == 5)
      acqResults = acquisition_4x5ms(data, settings);
    else
      acqResults = acquisition(data, settings);
    end
    
    plotAcquisition(acqResults);
  end

// Initialize channels and prepare for the run ============================
  
  // Start further processing only if a GNSS signal was acquired (the
  // field FREQUENCY will be set to 0 for all not acquired signals)
  if (or(acqResults.carrFreq))
    channel = preRun(acqResults, settings);
    showChannelStatus(channel, settings);
  else
    // No satellites to track, exit
    printf('No GNSS signals detected, signal processing finished.\n');
    trackResults = [];
    return;
  end

// Track the signal =======================================================
  startTime = now();
  [Y1,M1,D1,H1,MI1,S1]=datevec(startTime);
  printf('   Tracking started at %d:%d:%d\n', H1, MI1, S1);
  
  // Process all channels for given data block
  [trackResults, channel] = tracking(fid, channel, settings);
  
  // Close the data file
  mclose(fid);
  
  deltaTime = now() - startTime;
  [Y2,M2,D2,H2,MI2,S2]=datevec(deltaTime);
  printf('   Tracking is over (elapsed time %d:%d:%d)\n', H2, MI2, S2);
  
  // Auto save the acquisition & tracking results to a file to allow
  // running the positioning solution afterwards.
  printf('   Saving Acq & Tracking results to file trackingResults.dat\n')
  save('trackingResults.dat', trackResults, settings, acqResults, channel);
  
// Calculate navigation solutions =========================================
  printf('   Calculating navigation solutions...\n');
  //navSolutions = postNavigation(trackResults, settings);
  printf('   Processing is complete for this data block\n');
  
// Plot all results ===================================================
  printf('   Ploting results...\n');
  if settings.plotTracking
    plotTracking(1:settings.numberOfChannels, trackResults, settings);
  end
  
  //plotNavigation(navSolutions, settings);
  
  printf('Post processing of the signal is over.\n');
  
else
  // Error while opening the data file.
  error('Unable to read file %s: %s.', settings.fileName, message);
end // if (fid > 0)
