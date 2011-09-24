function showChannelStatus(channel, settings)
//Prints the status of all channels in a table.
//
//showChannelStatus(channel, settings)
//
//   Inputs:
//       channel     - data for each channel. It is used to initialize and
//                   at the processing of the signal (tracking part).
//       settings    - receiver settings

//--------------------------------------------------------------------------
//                           SoftGNSS v3.0
// 
// Copyright (C) Peter Rinder and Nicolaj Bertelsen
// Written by Peter Rinder Nicolaj Bertelsen and Darius Plausinaitis
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

  printf('\n*=========*=====*===============*===========*=============*========*\n');
  printf('| Channel | PRN |   Frequency   |  Doppler  | Code Offset | Status |\n');
  printf('*=========*=====*===============*===========*=============*========*\n');

  for channelNr = 1 : settings.numberOfChannels
    if (channel(channelNr).status ~= '-')
      printf('|      %2d | %3d |  %12.0f |   %5.0f   |    %6d   |     %1s  |\n', ...
              channelNr, ...
              channel(channelNr).PRN, ...
              channel(channelNr).acquiredFreq, ...
              channel(channelNr).acquiredFreq - (settings.IF + channel(channelNr).PRN*0.5625e6), ...
              channel(channelNr).codePhase, ...
              channel(channelNr).status);
    else
      printf('|      %2d | --- |  ------------ |   -----   |    ------   |   Off  |\n', ...
              channelNr);
    end
  end

  printf('*=========*=====*===============*===========*=============*========*\n\n');

endfunction
