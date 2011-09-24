//--------------------------------------------------------------------------
//                           SoftGNSS v3.0 GLONASS version
// 
// Copyright (C) Darius Plausinaitis and Dennis M. Akos
// Written by Darius Plausinaitis and Dennis M. Akos
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
//
//Script initializes settings and environment of the software receiver.
//Then the processing is started.

// Clean up the environment first =========================================
clear; xdel(winsid()); clc;

format('v', 11);

stacksize(55e6);

//--- Include folders with functions ---------------------------------------
exec('./include/calcLoopCoef.sci');
exec('./include/ephemeris.sci');
exec('./include/generateCAcode.sci');
exec('./include/makeCaTable.sci');
exec('./include/preRun.sci');
exec('./include/showChannelStatus.sci');
exec('./include/decode_gl_data.sci');

exec('./geoFunctions/satposg.sci');
exec('./geoFunctions/deltasatposg.sci');
exec('./geoFunctions/tropo.sci');
exec('./geoFunctions/e_r_corr.sci');
exec('./geoFunctions/topocent.sci');
exec('./geoFunctions/togeod.sci');
exec('./geoFunctions/leastSquarePos.sci');
exec('./geoFunctions/cart2geo.sci');
exec('./geoFunctions/findUtmZone.sci');
exec('./geoFunctions/cart2utm.sci');
exec('./geoFunctions/clsin.sci');
exec('./geoFunctions/clksin.sci');
exec('./geoFunctions/dms2mat.sci');
exec('./geoFunctions/deg2dms.sci');
exec('./geoFunctions/roundn.sci');

exec('./initSettings.sci');
exec('./probeData.sci');
exec('./acquisition.sci');
exec('./plotAcquisition.sci');
exec('./tracking.sci');
exec('./plotTracking.sci');
exec('./calculatePseudoranges.sci');
exec('./findTimeMarks.sci');
exec('./postNavigation.sci');
exec('./plotNavigation.sci');

// Print startup ==========================================================

printf('\n');
printf('Welcome to:  softGNSS\n\n');
printf('An open source GNSS SDR software project initiated by:\n\n');
printf('              Danish GPS Center/Aalborg University\n\n');
printf('The code was improved by GNSS Laboratory/University of Colorado.\n\n');
printf('The code was improved by gnss-sdr.com.\n\n');
printf('The software receiver softGNSS comes with ABSOLUTELY NO WARRANTY;\n');
printf('for details please read license details in the file license.txt. This\n');
printf('is free software, and  you  are  welcome  to  redistribute  it under\n');
printf('the terms described in the license.\n\n');

// Initialize constants, settings =========================================
settings = initSettings();

// Generate plot of raw data and ask if ready to start processing =========
try
    printf('Probing data (%s)...\n', settings.fileName);
    probeData(settings);
catch
    // There was an error, print it and exit
    disp(lasterror());
    printf('  (run setSettings or change settings in initSettings.sci to reconfigure)');
    return;
end
    
printf('  Raw IF data plotted \n');
printf('  (run setSettings or change settings in initSettings.sci to reconfigure)');
printf(' ');
gnssStart = input('Enter {1} to initiate GNSS processing or {0} to exit : ');

if (gnssStart == 1)
    printf(' ');
    //start things rolling...
    exec('./postProcessing.sce');
end
