function plotTracking(channelList, trackResults, settings)
//This function plots the tracking results for the given channel list.
//
//plotTracking(channelList, trackResults, settings)
//
//   Inputs:
//       channelList     - list of channels to be plotted.
//       trackResults    - tracking results from the tracking function.
//       settings        - receiver settings.

//--------------------------------------------------------------------------
//                           SoftGNSS v3.0
// 
// Copyright (C) Darius Plausinaitis
// Written by Darius Plausinaitis
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

//CVS record:
//Id: plotTracking.m,v 1.5.2.23 2006/08/14 14:45:14 dpl Exp

// Protection - if the list contains incorrect channel numbers
channelList = intersect(channelList, 1:settings.numberOfChannels);

//=== For all listed channels ==============================================
for channelNr = channelList

// Select (or create) and clear the figure ================================
    // The number 200 is added just for more convenient handling of the open
    // figure windows, when many figures are closed and reopened.
    // Figures drawn or opened by the user, will not be "overwritten" by
    // this function.

    fgrMsg = strcat(['Channel ', string(channelNr), ' (PRN ', ...
              string(trackResults(channelNr).PRN), ') results']);
    figure(channelNr+200, "Figure_name", fgrMsg);
    clf(channelNr +200);

//// Plot all figures =======================================================

        timeAxisInSeconds = (1:settings.msToProcess)/1000;

        //----- Discrete-Time Scatter Plot ---------------------------------
        subplot(5,3,1);
        plot(trackResults(channelNr).I_P_P,...
                            trackResults(channelNr).Q_P_P, ...
                            '.');
        xtitle('Discrete-Time Scatter Plot', 'I prompt', 'Q prompt');
        
        //----- PLL discriminator unfiltered--------------------------------
        subplot(5,3,4);
        plot  (timeAxisInSeconds, ...
               trackResults(channelNr).pllDiscr, 'r');      
        xtitle('Raw PLL discriminator', 'Time (s)', 'Amplitude');
        
        //----- PLL discriminator filtered----------------------------------
        subplot(5,3,7);
        plot  (timeAxisInSeconds, ...
               trackResults(channelNr).pllDiscrFilt, 'b');      
        xtitle('Filtered PLL discriminator', 'Time (s)', 'Amplitude');

        //----- DLL discriminator unfiltered--------------------------------
        subplot(5,3,11);
        plot  (timeAxisInSeconds, ...
               trackResults(channelNr).dllDiscr, 'r');      
        xtitle('Raw DLL discriminator', 'Time (s)', 'Amplitude');

        //----- DLL discriminator filtered----------------------------------
        subplot(5,3,12);
        plot  (timeAxisInSeconds, ...
               trackResults(channelNr).dllDiscrFilt, 'b');      
        xtitle('Filtered DLL discriminator', 'Time (s)', 'Amplitude');

        //----- Nav bits ---------------------------------------------------
        subplot(5,2,2);
        plot  (timeAxisInSeconds, ...
               trackResults(channelNr).I_P_P, ...
               timeAxisInSeconds, ...
               trackResults(channelNr).Q_P_P);
        xtitle('Bits of the navigation message', 'Time (s)');

        //----- Correlation ------------------------------------------------
        subplot(5,2,4);
        plot(timeAxisInSeconds, ...
             [sqrt(trackResults(channelNr).I_P_E.^2 + ...
                   trackResults(channelNr).Q_P_E.^2)', ...
             sqrt(trackResults(channelNr).I_P_P.^2 + ...
                 trackResults(channelNr).Q_P_P.^2)', ...
             sqrt(trackResults(channelNr).I_P_L.^2 + ...
                  trackResults(channelNr).Q_P_L.^2)'], ...
             '-*');
        
        legend("$\sqrt{I_{P}_{E}^2 + Q_{P}_{E}^2}$", "$\sqrt{I_{P}_{P}^2 + Q_{P}_{P}^2}$", ...
               "$\sqrt{I_{P}_{L}^2 + Q_{P}_{L}^2}$");
         
        //----- Correlation2 -----------------------------------------------
        subplot(5,2,6);
        plot(timeAxisInSeconds, ...
             [sqrt(trackResults(channelNr).I_E_P.^2 + ...
                   trackResults(channelNr).Q_E_P.^2)', ...
             sqrt(trackResults(channelNr).I_P_P.^2 + ...
                 trackResults(channelNr).Q_P_P.^2)', ...
             sqrt(trackResults(channelNr).I_L_P.^2 + ...
                  trackResults(channelNr).Q_L_P.^2)'], ...
             '-*');
        
        legend("$\sqrt{I_{E}_{P}^2 + Q_{E}_{P}^2}$", "$\sqrt{I_{P}_{P}^2 + Q_{P}_{P}^2}$", ...
               "$\sqrt{I_{L}_{P}^2 + Q_{L}_{P}^2}$");
        
        //----- SLL discriminator unfiltered--------------------------------
        subplot(5,3,14);
        plot  (timeAxisInSeconds, ...
               trackResults(channelNr).sllDiscr, 'r');      
        xtitle('Raw SLL discriminator', 'Time (s)', 'Amplitude');

        //----- SLL discriminator filtered----------------------------------
        subplot(5,3,15);
        plot  (timeAxisInSeconds, ...
               trackResults(channelNr).sllDiscrFilt, 'b');      
        xtitle('Filtered SLL discriminator', 'Time (s)', 'Amplitude');
        
end // for channelNr = channelList

endfunction
