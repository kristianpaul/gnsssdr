function plotAcquisition(acqResults)
//Functions plots bar plot of acquisition results (acquisition metrics). No
//bars are shown for the satellites not included in the acquisition list (in
//structure SETTINGS). 
//
//plotAcquisition(acqResults)
//
//   Inputs:
//       acqResults    - Acquisition results from function acquisition.

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

  // Plot all results =======================================================
  figure(101);

  bar(6:-1:-7, acqResults.peakMetric, 'blue');

  xtitle('Acquisition results', 'FCH number (no bar - SV is not in the acquisition list)', 'Acquisition Metric');

  // Mark acquired signals ==================================================

  acquiredSignals = acqResults.peakMetric .* (acqResults.carrFreq ~= 0);

  bar (6:-1:-7, acquiredSignals, 'green');
  legend('Not acquired signals', 'Acquired signals');

endfunction
