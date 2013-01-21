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

  //Local variables (to speed up code, bacause working with structs is slow):
  trkRslt_I_P = zeros(size(trackResults, 2), (settings.msToProcess - settings.skipNumberOfFirstBits));
  for i = 1:size(trackResults, 2)
    trkRslt_status(i)   = trackResults.status(i);
    trkRslt_I_P(i,:)    = trackResults(i).I_P((settings.skipNumberOfFirstBits+1):$);
    trkRslt_PRN(i)      = trackResults(i).PRN;
    absoluteSample(i,:) = trackResults(i).absoluteSample((settings.skipNumberOfFirstBits+1):$);
  end

  set_numberOfChnls       = settings.numberOfChannels;
  set_c                   = settings.c;
  set_navSolPeriod        = settings.navSolPeriod;
  set_elevationMask       = settings.elevationMask;
  set_useTropCorr         = settings.useTropCorr;
  set_samplesPerCode      = round(settings.samplingFreq / ...
                               (settings.codeFreqBasis / settings.codeLength));
  set_dataTypeSizeInBytes = settings.dataTypeSizeInBytes
  //Local variables - end.

  svnCount = sum(trkRslt_status == 'T');

  if (settings.msToProcess < 39000) | (svnCount < 4)
    // Show the error message and exit
    printf('Record is too short or too few satellites tracked. Exiting!\n');
    navSolutions = [];
    eph          = [];
    return
  end

  // Find time marks start positions ==========================================
  [subFrameStart, activeChnList] =.. 
             findSubframeStart(trkRslt_status, trkRslt_I_P, set_numberOfChnls);
  //pause;
  // Decode ephemerides =====================================================
  for channelNr = activeChnList

    //Add condition for the case of weak signal (Not all nav data is available):
    delFromActiveChnList = [];
    if (subFrameStart(channelNr) + (30000) -1) > length(trkRslt_I_P(channelNr,:)) then
      delFromActiveChnList = [delFromActiveChnList channelNr];
      //activeChnList = setdiff(activeChnList, channelNr);
      //stringStart(channelNr) = []
      //continue;
    else
      //--- Copy 5 subframes long record from tracking output ---------------
      navBitsSamples = trkRslt_I_P(channelNr, subFrameStart(channelNr) : ...
                              subFrameStart(channelNr) + (30000) -1)';
      //--- Convert prompt correlator output to +-1 ---------
      navBitsSamples = sign(navBitsSamples');
      //--- Decode data and extract ephemeris information ---
      [eph(trkRslt_PRN(channelNr)), SOW(trkRslt_PRN(channelNr))] = ephemeris(navBitsSamples);

      //--- Exclude satellite if it does not have the necessary nav data -----
      // we will check existence of at least one variable from each 
      // navigation string. It would be better to check existence of all variable 
      // but in this case the condition will be too huge and unclear!
      if (isempty(eph(trackResults(channelNr).PRN).IODC) | ... 
          isempty(eph(trackResults(channelNr).PRN).M_0) | ...
          isempty(eph(trackResults(channelNr).PRN).i_0) );
      
        //--- Exclude channel from the list (from further processing) ------
        //activeChnList = setdiff(activeChnList, channelNr);
        delFromActiveChnList = [delFromActiveChnList channelNr];
      end
      
      //--- Exclude satellite if it has MSB of health flag set:
      if ( eph(trackResults(channelNr).PRN).SatH1 == 1 )
        //activeChnList = setdiff(activeChnList, channelNr);
        ///delFromActiveChnList = [delFromActiveChnList channelNr];//temporary disable...
      end
    end
  end
  //pause;
  ///activeChnList(delFromActiveChnList) = [];//temporary disable
  ///subFrameStart(delFromActiveChnList) = [];//temporary disable

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
  satElev  = %inf*ones(1, set_numberOfChnls);

  // Save the active channel list. The list contains satellites that are
  // tracked and have the required ephemeris data. In the next step the list
  // will depend on each satellite's elevation angle, which will change over
  // time.  
  readyChnList = activeChnList;
  
  transmitTime = SOW;
  //pause;
  //##########################################################################
  //#   Do the satellite and receiver position calculations                  #
  //##########################################################################
  
  // Initialization of current measurement ==================================
  for currMeasNr = 1:fix((settings.msToProcess - max(subFrameStart) -..
                           settings.skipNumberOfFirstBits) / ... 
                         set_navSolPeriod)
    // Exclude satellites, that are belove elevation mask 
    ///activeChnList = intersect(find(satElev >= set_elevationMask), ...
    ///                          readyChnList);

    // Save list of satellites used for position calculation
    navSol_channel_SVN(activeChnList, currMeasNr) = trkRslt_PRN(activeChnList);

    // These two lines help the skyPlot function. The satellites excluded
    // do to elevation mask will not "jump" to possition (0,0) in the sky
    // plot.
    navSol_channel_el(:, currMeasNr) = %nan*ones(set_numberOfChnls, 1);
    navSol_channel_az(:, currMeasNr) = %nan*ones(set_numberOfChnls, 1);

    // Find pseudoranges ======================================================
    navSol_channel_rawP(:, currMeasNr) = calculatePseudoranges(...
            set_numberOfChnls, set_samplesPerCode, absoluteSample,...
            set_c, set_dataTypeSizeInBytes, ...
            subFrameStart + set_navSolPeriod * (currMeasNr-1), activeChnList)';

    // Find satellites positions and clocks corrections =======================
    [satPositions, satClkCorr] = satpos(transmitTime, ...
                                        [trackResults(activeChnList).PRN], ...
                                        eph, settings);
    //pause;
    // Find receiver position =================================================

    // 3D receiver position can be found only if signals from more than 3
    // satellites are available
    if length(activeChnList) > 3
      
      //=== Calculate receiver position ==================================
      [xyzdt sat_el sat_az sat_dop] = leastSquarePos(satPositions, ...
                         navSol_channel_rawP(activeChnList, currMeasNr)' - ...
                         satClkCorr * set_c, ...
                         set_c, set_useTropCorr);
      navSol_channel_el(activeChnList, currMeasNr) = sat_el';
      navSol_channel_az(activeChnList, currMeasNr) = sat_az';
      navSol_DOP(:, currMeasNr) = sat_dop';
//       //Transform from PZ90.02 to WGS84!
//       xyz = xyzdt(1:3);
//       xyz = [-1.1 -0.3 -0.9] + (1-0.12e-6).*([1 -0.82e-6 0; 0.82e-6 1 0; 0 0 1] * xyz')';
//       xyzdt(1:3) = xyz;
//
//       navSol_channel_el(activeChnList, currMeasNr) = sat_el';
//       navSol_channel_az(activeChnList, currMeasNr) = sat_az';
//       navSol_DOP(:, currMeasNr) = sat_dop';

      //--- Save results -------------------------------------------------
      navSol_X(currMeasNr)  = xyzdt(1);
      navSol_Y(currMeasNr)  = xyzdt(2);
      navSol_Z(currMeasNr)  = xyzdt(3);
      navSol_dt(currMeasNr) = xyzdt(4);

      // Update the satellites elevations vector
      satElev = navSol_channel_el(:, currMeasNr);

      //=== Correct pseudorange measurements for clocks errors ===========
      navSol_channel_corrP(activeChnList, currMeasNr) = ...
              navSol_channel_rawP(activeChnList, currMeasNr) - ...
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

      navSol_channel_az(activeChnList, currMeasNr) = %nan*ones(length(activeChnList),1);
      navSol_channel_el(activeChnList, currMeasNr) = %nan*ones(length(activeChnList),1);

      // TODO: Know issue. Satellite positions are not updated if the
      // satellites are excluded do to elevation mask. Therefore raising
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
  navSolutions.channel.SVN        = navSol_channel_SVN;
  navSolutions.channel.el         = navSol_channel_el;
  navSolutions.channel.az         = navSol_channel_az;
  navSolutions.channel.rawP       = navSol_channel_rawP;
  navSolutions.channel.correctedP = navSol_channel_corrP;

endfunction
