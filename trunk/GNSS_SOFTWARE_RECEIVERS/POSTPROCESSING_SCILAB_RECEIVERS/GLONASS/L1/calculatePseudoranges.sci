function [pseudoranges] = calculatePseudoranges(numberOfChannels, samplesPerCode,...
                                                absoluteSample, startOffset, c, ...
                                                msOfTheSignal, channelList)
//calculatePseudoranges finds relative pseudoranges for all satellites
//listed in CHANNELLIST at the specified millisecond of the processed
//signal. The pseudoranges contain unknown receiver clock offset. It can be
//found by the least squares position search procedure. 
//
//[pseudoranges] = calculatePseudoranges(trackResults, msOfTheSignal, ...
//                                       channelList, settings)
//
//   Inputs:
//       numberOfChannels  - number of Channels
//       samplesPerCode    - samples number per code
//       absoluteSample    - trackResults.absoluteSample
//       startOffset       - settings.startOffset
//       c                 - speed of light
//       msOfTheSignal     - 
//       channelList       - list of Channels
//   Outputs:
//       pseudoranges      - relative pseudoranges to the satellites. 

//--------------------------------------------------------------------------
//                           SoftGNSS v3.0
// 
// Copyright (C) Darius Plausinaitis
// Written by Darius Plausinaitis
// Based on Peter Rinder and Nicolaj Bertelsen
// Updated and converted to scilab 5.3.0 by Artyom Gavrilov
//--------------------------------------------------------------------------
//
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

//--- Set initial travel time to infinity ----------------------------------
// Later in the code a shortest pseudorange will be selected. Therefore
// pseudoranges from non-tracking channels must be the longest - e.g.
// infinite. 

travelTime = %inf*ones(1, numberOfChannels);

//--- For all channels in the list ... 
for channelNr = channelList
    //--- Compute the travel times -----------------------------------------    
    travelTime(channelNr) = ...
          absoluteSample(channelNr, msOfTheSignal(channelNr)) / samplesPerCode;
end

//--- Truncate the travelTime and compute pseudoranges ---------------------
minimum         = floor(min(travelTime));
travelTime      = travelTime - minimum;

//--- Convert travel time to a distance ------------------------------------
// The speed of light must be converted from meters per second to meters
// per millisecond. 
pseudoranges    = travelTime * (c / 1000);

endfunction
