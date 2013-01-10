function [trackResults, channel]= tracking(fid, channel, settings)
// Performs code and carrier tracking for all channels.
//
//[trackResults, channel] = tracking(fid, channel, settings)
//
//   Inputs:
//       fid             - file identifier of the signal record.
//       channel         - PRN, carrier frequencies and code phases of all
//                       satellites to be tracked (prepared by preRum.m from
//                       acquisition results).
//       settings        - receiver settings.
//   Outputs:
//       trackResults    - tracking results (structure array). Contains
//                       in-phase prompt outputs and absolute spreading
//                       code's starting positions, together with other
//                       observation data from the tracking loops. All are
//                       saved every millisecond.

//--------------------------------------------------------------------------
//                           SoftGNSS v3.0
// 
// Copyright (C) Dennis M. Akos
// Written by Darius Plausinaitis and Dennis M. Akos
// Based on code by DMAkos Oct-1999
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

// Initialize result structure ============================================

  // Channel status
  trackResults.status         = '-';      // No tracked signal, or lost lock

  // The absolute sample in the record of the C/A code start:
  trackResults.absoluteSample = zeros(1, settings.msToProcess);
  
  // Freq of the C/A code:
  trackResults.codeFreq       = ones(1, settings.msToProcess).*%inf;
  
  // Frequency of the tracked carrier wave:
  trackResults.carrFreq       = ones(1, settings.msToProcess).*%inf;
  
  // Outputs from the correlators (In-phase):
  trackResults.I_P            = zeros(1, settings.msToProcess);
  trackResults.I_E            = zeros(1, settings.msToProcess);
  trackResults.I_L            = zeros(1, settings.msToProcess);
  
  // Outputs from the correlators (Quadrature-phase):
  trackResults.Q_E            = zeros(1, settings.msToProcess);
  trackResults.Q_P            = zeros(1, settings.msToProcess);
  trackResults.Q_L            = zeros(1, settings.msToProcess);
  
  // Loop discriminators
  trackResults.dllDiscr       = ones(1, settings.msToProcess).*%inf;
  trackResults.dllDiscrFilt   = ones(1, settings.msToProcess).*%inf;
  trackResults.pllDiscr       = ones(1, settings.msToProcess).*%inf;
  trackResults.pllDiscrFilt   = ones(1, settings.msToProcess).*%inf;
  
  //--- Copy initial settings for all channels -------------------------------
  if settings.numberOfChannels > 0 then
    trackResults_tmp = trackResults;
    for i=2:settings.numberOfChannels
      trackResults_tmp = [trackResults_tmp trackResults];
    end;
    trackResults = trackResults_tmp;
    clear trackResults_tmp;  
  else
    clear trackResults;
  end;
  
  // Initialize tracking variables ==========================================
  
  codePeriods = settings.msToProcess;     // For GPS one C/A code is one ms
  
  // CodeLength:
  settings_codeLength = settings.codeLength*2;
  
  //--- DLL variables --------------------------------------------------------
  // Define early-late offset (in chips)
  earlyLateSpc = settings.dllCorrelatorSpacing;
  
  // Summation interval
  PDIcode = 0.001;
  
  // Calculate filter coefficient values
  [tau1code, tau2code] = calcLoopCoef(settings.dllNoiseBandwidth, ...
                                      settings.dllDampingRatio, ...
                                      1.0);
  
  //--- PLL variables --------------------------------------------------------
  // Summation interval
  PDIcarr = 0.001;
  
  // Calculate filter coefficient values
  ///[tau1carr, tau2carr] = calcLoopCoef(settings.pllNoiseBandwidth, ...
  ///                                    settings.pllDampingRatio, ...
  ///                                    0.25);
  [k1 k2 k3] = calcFLLPLLLoopCoef(settings.pllNoiseBandwidth, ...
                                  settings.fllNoiseBandwidth, PDIcarr);
  hwb = waitbar(0,'Tracking...');
  
  //Will we work with I-only data or IQ data.
  if (settings.fileType==1)
    dataAdaptCoeff=1;
  else
    dataAdaptCoeff=2;
  end
  
  // Start processing channels ==============================================
  for channelNr = 1:settings.numberOfChannels
    
    // Only process if PRN is non zero (acquisition was successful)
    if (channel(channelNr).PRN ~= 0)
      // Save additional information - each channel's tracked PRN
      trackResults(channelNr).PRN     = channel(channelNr).PRN;
      
      // Move the starting point of processing. Can be used to start the
      // signal processing at any point in the data record (e.g. for long
      // records). In addition skip through that data file to start at the
      // appropriate sample (corresponding to code phase). Assumes sample
      // type is schar (or 1 byte per sample):
      mseek(dataAdaptCoeff * ...
            (settings.skipNumberOfBytes + channel(channelNr).codePhase-1), fid);

      // Get a vector with the C/A code sampled 1x/chip
      caCode = readE1Bcode(channel(channelNr).PRN);
      caCode = kron(caCode, ones(1,2));//repeat each symbol twice;
      meandr = ones(1, settings.codeLength*2);
      meandr(2:2:$) = -1;
      caCode = caCode .* meandr;
      // Then make it possible to do early and late versions
      ///caCode = [caCode($) caCode caCode(1)]; //length=8186
      cacCode(1,:) = [caCode($)    caCode(1:2046)    caCode(2047)];
      cacCode(2,:) = [caCode(2046) caCode(2047:4092) caCode(4093)];
      cacCode(3,:) = [caCode(4092) caCode(4093:6138) caCode(6139)];
      cacCode(4,:) = [caCode(6138) caCode(6139:8184) caCode(1)];
      caCode = [caCode($) caCode caCode(1)]; //length=8186
      
      //--- Perform various initializations ------------------------------
      
      // define initial code frequency basis of NCO
      codeFreq      = 2*settings.codeFreqBasis; //2.046e6
      // define residual code phase (in chips)
      remCodePhase   = 0.0;
      remCodePhase2  = 0.0;
      remCodePhase2_cnt  = 1;// РАЗОБРАТЬСЯ ПОЧЕМУ ТАК?!!!
      // define carrier frequency which is used over whole tracking period
      carrFreq      = channel(channelNr).acquiredFreq;
      carrFreqBasis = channel(channelNr).acquiredFreq;
      // define residual carrier phase
      remCarrPhase  = 0.0;
      
      //code tracking loop parameters
      oldCodeNco   = 0.0;
      oldCodeError = 0.0;
      
      //carrier/Costas loop parameters
      oldCarrNco   = 0.0;
      oldCarrError = 0.0;
      
      //frequency lock loop parameters
      oldFreqNco   = 0.0;
      oldFreqError = 0.0;
      
      //explain this!
      I1 = 0.001; I2 = 0.001; Q1 = 0.001; Q2 = 0.001;
      
      //temp variables! We have to use them in order to speed up the code!
      //Structs are extemly slow in scilab 5.3.0 :(
      loopCnt_carrFreq       = ones(1,  settings.msToProcess);
      loopCnt_codeFreq       = ones(1,  settings.msToProcess);
      loopCnt_absoluteSample = zeros(1, settings.msToProcess);
      loopCnt_dllDiscr       = ones(1,  settings.msToProcess);
      loopCnt_dllDiscrFilt   = ones(1,  settings.msToProcess);
      loopCnt_pllDiscr       = ones(1,  settings.msToProcess);
      loopCnt_pllDiscrFilt   = ones(1,  settings.msToProcess);
      loopCnt_I_E            = zeros(1, settings.msToProcess);
      loopCnt_I_P            = zeros(1, settings.msToProcess);
      loopCnt_I_L            = zeros(1, settings.msToProcess);
      loopCnt_Q_E            = zeros(1, settings.msToProcess);
      loopCnt_Q_P            = zeros(1, settings.msToProcess);
      loopCnt_Q_L            = zeros(1, settings.msToProcess);
      
      loopCnt_samplingFreq     = settings.samplingFreq;
      loopCnt_codeLength       = 2*settings.codeLength;
      loopCnt_dataType         = settings.dataType;
      loopCnt_codeFreqBasis    = 2*settings.codeFreqBasis;
      loopCnt_numberOfChannels = settings.numberOfChannels
      
      //=== Process the number of specified code periods =================
      for loopCnt =  1:codePeriods
        
        // GUI update -------------------------------------------------------------
        // The GUI is updated every 50ms.
        if (  (loopCnt-fix(loopCnt/50)*50) == 0  )
        //Should be corrected in future! Doesn't work like original version :(
          try
            wbrMsg = strcat(['Tracking: Ch ' string(channelNr) ' of ' ...
                            string(loopCnt_numberOfChannels) '; PRN#' ...
                            string(channel(channelNr).PRN)]);
            waitbar(loopCnt/codePeriods, wbrMsg, hwb); 
          catch
            // The progress bar was closed. It is used as a signal
            // to stop, "cancel" processing. Exit.
            disp('Progress bar closed, exiting...');
            return
          end
        end
        
// Read next block of data ------------------------------------------------            
        // Find the size of a "block" or code period in whole samples
        
        // Update the phasestep based on code freq (variable) and
        // sampling frequency (fixed)
        codePhaseStep = codeFreq / loopCnt_samplingFreq; //2.046e6/16e6
        
        blksize = ceil((loopCnt_codeLength/4-remCodePhase) / codePhaseStep);
        
        // Read in the appropriate number of samples to process this
        // interation 
        rawSignal = mget(dataAdaptCoeff*blksize, loopCnt_dataType, fid);
        samplesRead = length(rawSignal);
        
        if (dataAdaptCoeff==2)
          rawSignal1 = rawSignal(1:2:$);
          rawSignal2 = rawSignal(2:2:$);
          rawSignal = rawSignal1 + %i .* rawSignal2;  //transpose vector
        end
        
        
        // If did not read in enough samples, then could be out of 
        // data - better exit 
        if (samplesRead ~= dataAdaptCoeff*blksize)
          disp('Not able to read the specified number of samples  for tracking, exiting!')
          mclose(fid);
          return
        end
        
// Set up all the code phase tracking information -------------------------
        // Define index into early code vector
        tcode       = (remCodePhase-earlyLateSpc) : ...
                       codePhaseStep : ...
                       ((blksize-1)*codePhaseStep+remCodePhase-earlyLateSpc);
        tcode2      = ceil(tcode) + 1;
        earlyCode   = cacCode(remCodePhase2_cnt, tcode2);
        
        // Define index into late code vector
        tcode       = (remCodePhase+earlyLateSpc) : ...
                       codePhaseStep : ...
                       ((blksize-1)*codePhaseStep+remCodePhase+earlyLateSpc);
        tcode2      = ceil(tcode) + 1;
        lateCode    = cacCode(remCodePhase2_cnt, tcode2);
        
        // Define index into prompt code vector
        tcode       = remCodePhase : ...
                      codePhaseStep : ...
                      ((blksize-1)*codePhaseStep+remCodePhase);
        tcode2      = ceil(tcode) + 1;
        promptCode  = cacCode(remCodePhase2_cnt, tcode2);
        
        remCodePhase = (tcode(blksize) + codePhaseStep) - 2046.0;
        
        remCodePhase2_cnt = remCodePhase2_cnt+1;
        if (remCodePhase2_cnt > 4) then
          remCodePhase2_cnt = 1;
        end
        
// Generate the carrier frequency to mix the signal to baseband -----------
        time    = (0:blksize) ./ loopCnt_samplingFreq;
        
        // Get the argument to sin/cos functions
        trigarg = ((carrFreq * 2.0 * %pi) .* time) + remCarrPhase;
        remCarrPhase = trigarg(blksize+1)-...
                        fix(trigarg(blksize+1)./(2 * %pi)).*(2 * %pi);
        
        // Finally compute the signal to mix the collected data to
        // bandband
        carrsig = exp(%i .* trigarg(1:blksize));
        
// Generate the six standard accumulated values ---------------------------
        // First mix to baseband
        qBasebandSignal = real(carrsig .* rawSignal);
        iBasebandSignal = imag(carrsig .* rawSignal);
        
        // Now get early, late, and prompt values for each
        I_E = sum(earlyCode  .* iBasebandSignal);
        Q_E = sum(earlyCode  .* qBasebandSignal);
        I_P = sum(promptCode .* iBasebandSignal);
        Q_P = sum(promptCode .* qBasebandSignal);
        I_L = sum(lateCode   .* iBasebandSignal);
        Q_L = sum(lateCode   .* qBasebandSignal);
        
// Find combined PLL/FLL error and update carrier NCO (FLL-assisted PLL) ------
        I2 = I1;  Q2 = Q1;
        I1 = I_P; Q1 = Q_P;
        cross = I1*Q2 - I2*Q1;
        dot   = abs(I1*I2 + Q1*Q2);
        
        // Implement carrier loop discriminator (frequency detector)
        //freqError = atan(cross, dot)/(2*%pi)/0.001/500; //0.001 - integration periode. 500 - maximum discriminator output.
        freqError = atan(cross, dot) / %pi;  //normalized output in the range from -1 to +1.
        
        // Implement carrier loop discriminator (phase detector)
        carrError = atan(Q_P / I_P) / (2.0 * %pi);
        
        //Implement carrier loop filter and generate NCO command; 
        carrNco = oldCarrNco + k1*carrError - k2*oldCarrError - k3*freqError;
        //(PLL Bw = 25 Hz; FLL Bw = 250 Hz).
        //carrNco = oldCarrNco + (68.92)*carrError - (66.70)*oldCarrError - (1.0)*freqError;
        //(PLL Bw = 7 Hz; FLL Bw = 250 Hz).
        //carrNco = oldCarrNco + (18.85)*carrError - (18.68)*oldCarrError - (1.0)*freqError;
        
        oldCarrNco = carrNco;
        oldCarrError = carrError;
        
        carrFreq = carrFreqBasis + carrNco;
        
        loopCnt_carrFreq(loopCnt) = carrFreq;
        
// Find DLL error and update code NCO -------------------------------------
        codeError = (sqrt(I_E * I_E + Q_E * Q_E) - ...
                     sqrt(I_L * I_L + Q_L * Q_L)) / ...
                    (sqrt(I_E * I_E + Q_E * Q_E) +...
                     sqrt(I_L * I_L + Q_L * Q_L));
        
        // Implement code loop filter and generate NCO command
        codeNco = oldCodeNco + (tau2code/tau1code) * ...
                  (codeError - oldCodeError) + codeError * (PDIcode/tau1code);
        oldCodeNco   = codeNco;
        oldCodeError = codeError;
        
        // Modify code freq based on NCO command
        ///codeFreq = loopCnt_codeFreqBasis - codeNco;
        
        //example of PLL/FLL-assisted DLL for GPS. For GLONASS should be reworked!
        codeFreq = loopCnt_codeFreqBasis - codeNco + ( (carrFreq - settings.IF)/770 );
        
        
        loopCnt_codeFreq(loopCnt) = codeFreq;
        
// Record various measures to show in postprocessing ----------------------
        // Record sample number (based on 8bit samples)
        ///loopCnt_absoluteSample(loopCnt) =(mtell(fid))/dataAdaptCoeff;
        //[Art] Add assistance from carrier tracking loop:
        loopCnt_absoluteSample(loopCnt) = (mtell(fid))/dataAdaptCoeff - ...
                                          remCodePhase * ...
                                          (loopCnt_samplingFreq/1000)/settings_codeLength;

        loopCnt_dllDiscr(loopCnt)       = codeError;
        loopCnt_dllDiscrFilt(loopCnt)   = codeNco;
        loopCnt_pllDiscr(loopCnt)       = carrError;
        loopCnt_pllDiscrFilt(loopCnt)   = carrNco;
        
        loopCnt_I_E(loopCnt) = I_E;
        loopCnt_I_P(loopCnt) = I_P;
        loopCnt_I_L(loopCnt) = I_L;
        loopCnt_Q_E(loopCnt) = Q_E;
        loopCnt_Q_P(loopCnt) = Q_P;
        loopCnt_Q_L(loopCnt) = Q_L;
      end // for loopCnt

      // If we got so far, this means that the tracking was successful
      // Now we only copy status, but it can be update by a lock detector
      // if implemented
      trackResults(channelNr).status  = channel(channelNr).status;
      
      //Now copy all data from temp variable to the real place! 
      //We do it to speed up the code.
      trackResults(channelNr).carrFreq       = loopCnt_carrFreq;
      trackResults(channelNr).codeFreq       = loopCnt_codeFreq;
      trackResults(channelNr).absoluteSample = loopCnt_absoluteSample;
      trackResults(channelNr).dllDiscr       = loopCnt_dllDiscr;
      trackResults(channelNr).dllDiscrFilt   = loopCnt_dllDiscrFilt;
      trackResults(channelNr).pllDiscr       = loopCnt_pllDiscr;
      trackResults(channelNr).pllDiscrFilt   = loopCnt_pllDiscrFilt;
      trackResults(channelNr).I_E            = loopCnt_I_E;
      trackResults(channelNr).I_P            = loopCnt_I_P;
      trackResults(channelNr).I_L            = loopCnt_I_L;
      trackResults(channelNr).Q_E            = loopCnt_Q_E;
      trackResults(channelNr).Q_P            = loopCnt_Q_P;
      trackResults(channelNr).Q_L            = loopCnt_Q_L;
      
      
    end // if a PRN is assigned
end // for channelNr 

// Close the waitbar
winclose(hwb)

endfunction
