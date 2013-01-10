function [navSolutions, eph] = postNavigation(trackResults, settings)
//Function calculates navigation solutions for the receiver (pseudoranges,
//positions). At the end it converts coordinates from the WGS84 system to
//the UTM, geocentric or any additional coordinate system.
//
//[navSolutions, eph] = postNavigation(trackResults, settings)
//
//   Inputs:
//       trackResults    - results from the tracking function (structure
//                       array).
//       settings        - receiver settings.
//   Outputs:
//       navSolutions    - contains measured pseudoranges, receiver
//                       clock error, receiver coordinates in several
//                       coordinate systems (at least ECEF and UTM).
//       eph             - received ephemerides of all SV (structure array).

//--------------------------------------------------------------------------
//                           SoftGNSS v3.0
// 
// Copyright (C) Darius Plausinaitis
// Written by Darius Plausinaitis with help from Kristin Larson
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

// Check is there enough data to obtain any navigation solution ===========
// It is necessary to have at least three subframes (number 1, 2 and 3) to
// find satellite coordinates. Then receiver position can be found too.
// The function requires all 5 subframes, because the tracking starts at
// arbitrary point. Therefore the first received subframes can be any three
// from the 5.
// One subframe length is 6 seconds, therefore we need at least 30 sec long
// record (5 * 6 = 30 sec = 30000ms). We add extra seconds for the cases,
// when tracking has started in a middle of a subframe.

  //Local variables (to speed up code, bacause working with structs is slow):
  trkRslt_I_P = zeros(size(trackResults, 2), settings.msToProcess);
  for i = 1:size(trackResults, 2)
    trkRslt_status(i)   = trackResults.status(i);
    trkRslt_I_P(i,:)    = trackResults(i).I_P;
    trkRslt_PRN(i)      = trackResults(i).PRN;
    absoluteSample(i,:) = trackResults(i).absoluteSample;
  end

  set_numberOfChnls  = settings.numberOfChannels;
  set_startOffset    = settings.startOffset;
  set_c              = settings.c;
  set_navSolPeriod   = settings.navSolPeriod;
  set_elevationMask  = settings.elevationMask;
  set_useTropCorr    = settings.useTropCorr;
  set_samplesPerCode = round(settings.samplingFreq / (settings.codeFreqBasis / settings.codeLength));
  set_msToProcess    = settings.msToProcess;
  //Local variables - end.

  svnCount = sum(trkRslt_status == 'T');

  if (set_msToProcess < 36000) | (svnCount < 4)
    // Show the error message and exit
    printf('Record is to short or too few satellites tracked. Exiting!\n');
    navSolutions = [];
    eph          = [];
    return
  end
  
  // Find preamble start positions ==========================================
  [subFrameStart, activeChnList] = findPreambles(trkRslt_status, trkRslt_I_P, set_numberOfChnls);
  
  // Decode ephemerides =====================================================
  for channelNr = activeChnList
    
    //=== Convert tracking output to navigation bits =======================
    
    //--- Copy 5 sub-frames long record from tracking output ---------------
    ///navBitsSamples = trackResults(channelNr).I_P(subFrameStart(channelNr) - 20 : ...
    ///                           subFrameStart(channelNr) + (1500 * 20) -1)';
    navBitsSamples = trkRslt_I_P(channelNr, subFrameStart(channelNr) - 20 : ...
                                 subFrameStart(channelNr) + (1500 * 20) -1)';
    
    //--- Group every 20 vales of bits into columns ------------------------
    navBitsSamples = matrix(navBitsSamples, ...
                             20, (size(navBitsSamples, 1) / 20));
    
    //--- Sum all samples in the bits to get the best estimate -------------
    navBits = sum(navBitsSamples, 'r');
    
    //--- Now threshold and make 1 and 0 -----------------------------------
    // The expression (navBits > 0) returns an array with elements set to 1
    // if the condition is met and set to 0 if it is not met.
    //navBits = (navBits > 0);
    navBits = sign(navBits);
    navBits = (navBits + 1) / 2;
    
    //--- Convert from decimal to binary -----------------------------------
    // The function ephemeris expects input in binary form. In Matlab it is
    // a string array containing only "0" and "1" characters.
//    navBitsBin = dec2bin(navBits);
    navBitsBin = navBits;
    
    //=== Decode ephemerides and TOW of the first sub-frame ================
//    [eph(trackResults(channelNr).PRN), TOW] = ...
//                            ephemeris(navBitsBin(2:1501)', navBitsBin(1));
    [eph(trackResults(channelNr).PRN), TOW] = ephemeris(navBitsBin(2:1501), navBitsBin(1));

    //--- Exclude satellite if it does not have the necessary nav data -----
    if (isempty(eph(trackResults(channelNr).PRN).IODC) | ...
      isempty(eph(trackResults(channelNr).PRN).IODE_sf2) | ...
      isempty(eph(trackResults(channelNr).PRN).IODE_sf3))
      
      //--- Exclude channel from the list (from further processing) ------
      activeChnList = setdiff(activeChnList, channelNr);
    end    
  end

  // Check if the number of satellites is still above 3 =====================
  if (isempty(activeChnList) | (size(activeChnList, 2) < 4))
    // Show error message and exit
    printf('Too few satellites with ephemeris data for postion calculations. Exiting!\n');
    navSolutions = [];
    eph          = [];
    return
  end

  // Initialization =========================================================
  
  // Set the satellite elevations array to INF to include all satellites for
  // the first calculation of receiver position. There is no reference point
  // to find the elevation angle as there is no receiver position estimate at
  // this point.
  satElev  = %inf*ones(1, settings.numberOfChannels);
  
  // Save the active channel list. The list contains satellites that are
  // tracked and have the required ephemeris data. In the next step the list
  // will depend on each satellite's elevation angle, which will change over
  // time.  
  readyChnList = activeChnList;
  
  transmitTime = TOW;
  
  //##########################################################################
  //#   Do the satellite and receiver position calculations                  #
  //##########################################################################
  
  //Some tricks to speed up code. Structs are VERY SLOW in scilab 5.3.0.
  for ttt = 1:length(trackResults.PRN)
    loop_PRN(ttt) = trackResults(ttt).PRN;
  end
  // Initialization of current measurement ==================================
  for currMeasNr = 1:fix((set_msToProcess - max(subFrameStart)) / ...
                                                     set_navSolPeriod);
    
    // Exclude satellites, that are belove elevation mask 
    activeChnList = intersect(find(satElev >= set_elevationMask), ...
                                  readyChnList);
     
    // Save list of satellites used for position calculation
    navSol_channel_PRN(activeChnList, currMeasNr) = trkRslt_PRN(activeChnList);
    
    // These two lines help the skyPlot function. The satellites excluded
    // do to elevation mask will not "jump" to possition (0,0) in the sky
    // plot.
    navSol_channel_el(:, currMeasNr) = %nan*ones(set_numberOfChnls, 1);
    navSol_channel_az(:, currMeasNr) = %nan*ones(set_numberOfChnls, 1);

// Find pseudoranges ======================================================
    navSol_channel_rawP(:, currMeasNr) = calculatePseudoranges(...
            set_numberOfChnls, set_samplesPerCode,...
            absoluteSample, ...
            set_startOffset, set_c, ...
            subFrameStart + set_navSolPeriod * (currMeasNr-1), ...
            activeChnList)';

// Find satellites positions and clocks corrections =======================
    //pause;
    [satPositions, satClkCorr] = satpos(transmitTime, ...
                                        [trackResults(activeChnList).PRN], ...
                                        eph, settings);
    
// Find receiver position =================================================

    // 3D receiver position can be found only if signals from more than 3
    // satellites are available  
    if length(activeChnList) > 3

      //=== Calculate receiver position ==================================
      [a b c d] = leastSquarePos(satPositions, ...
                         navSol_channel_rawP(activeChnList, currMeasNr)' + ...
                         satClkCorr * set_c, ...
                         set_c, set_useTropCorr);
      xyzdt = a;
      navSol_channel_el(activeChnList, currMeasNr) = b';
      navSol_channel_az(activeChnList, currMeasNr) = c';
      navSol_DOP(:, currMeasNr) = d';
      clear a; clear b; clear c; clear d;
      
      //--- Save results -------------------------------------------------
      navSol_X(currMeasNr)  = xyzdt(1);
      navSol_Y(currMeasNr)  = xyzdt(2);
      navSol_Z(currMeasNr)  = xyzdt(3);
      navSol_dt(currMeasNr) = xyzdt(4);
      
      // Update the satellites elevations vector
      satElev = navSol_channel_el(:, currMeasNr);

      //=== Correct pseudorange measurements for clocks errors ===========
      navSol_channel_corrP(activeChnList, currMeasNr) = ...
              navSol_channel_rawP(activeChnList, currMeasNr) + ...
              satClkCorr' * set_c + navSol_dt(currMeasNr);

// Coordinate conversion ==================================================

      //=== Convert to geodetic coordinates ==============================
      [navSol_latitude(currMeasNr), ...
       navSol_longitude(currMeasNr), ...
       navSol_height(currMeasNr)] = cart2geo(...
                                          navSol_X(currMeasNr), ...
                                          navSol_Y(currMeasNr), ...
                                          navSol_Z(currMeasNr), ...
                                          5);

      //=== Convert to UTM coordinate system =============================
      navSol_UtmZone = findUtmZone(navSol_latitude(currMeasNr), ...
                                         navSol_longitude(currMeasNr));

      [navSol_E(currMeasNr), ...
       navSol_N(currMeasNr), ...
       navSol_U(currMeasNr)] = cart2utm(xyzdt(1), xyzdt(2), ...
                                              xyzdt(3), ...
                                              navSol_UtmZone);
      
    else // if size(activeChnList, 2) > 3 
      //--- There are not enough satellites to find 3D position ----------
      ///disp(['   Measurement No. ', num2str(currMeasNr), ...
      ///               ': Not enough information for position solution.']);
      
      //--- Set the missing solutions to NaN. These results will be
      //excluded automatically in all plots. For DOP it is easier to use
      //zeros. NaN values might need to be excluded from results in some
      //of further processing to obtain correct results.
      navSol_X(currMeasNr)           = %nan;
      navSol_Y(currMeasNr)           = %nan;
      navSol_Z(currMeasNr)           = %nan;
      navSol_dt(currMeasNr)          = %nan;
      navSol_DOP(:, currMeasNr)      = zeros(5, 1);
      navSol_latitude(currMeasNr)    = %nan;
      navSol_longitude(currMeasNr)   = %nan;
      navSol_height(currMeasNr)      = %nan;
      navSol_E(currMeasNr)           = %nan;
      navSol_N(currMeasNr)           = %nan;
      navSol_U(currMeasNr)           = %nan;

      navSol_channel_az(activeChnList, currMeasNr) = ...
                                      %nan .* ones(1, length(activeChnList));
      navSol_channel_el(activeChnList, currMeasNr) = ...
                                      %nan .* ones(1, length(activeChnList));
      
      // TODO: Know issue. Satellite positions are not updated if the
      // satellites are excluded do to elevation mask. Therefore rasing
      // satellites will be not included even if they will be above
      // elevation mask at some point. This would be a good place to
      // update positions of the excluded satellites.
      
    end // if size(activeChnList, 2) > 3
    
    //=== Update the transmit time ("measurement time") ====================
    transmitTime = transmitTime + set_navSolPeriod / 1000;
    
  end //for currMeasNr...
  
  //Some trciks to speed up code. Structs are VERY SLOW in scilab 5.3.0.
  navSolutions.X                  = navSol_X;
  navSolutions.Y                  = navSol_Y;
  navSolutions.Z                  = navSol_Z;
  navSolutions.dt                 = navSol_dt;
  navSolutions.latitude           = navSol_latitude;
  navSolutions.longitude          = navSol_longitude;
  navSolutions.height             = navSol_height;
  navSolutions.utmZone            = navSol_UtmZone;
  navSolutions.E                  = navSol_E;
  navSolutions.N                  = navSol_N;
  navSolutions.U                  = navSol_U;
  navSolutions.DOP                = navSol_DOP;
  navSolutions.channel.PRN        = navSol_channel_PRN;
  navSolutions.channel.el         = navSol_channel_el;
  navSolutions.channel.az         = navSol_channel_az;
  navSolutions.channel.rawP       = navSol_channel_rawP;
  navSolutions.channel.correctedP = navSol_channel_corrP;
  
endfunction
