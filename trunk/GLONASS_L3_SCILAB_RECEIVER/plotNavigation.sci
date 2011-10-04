function plotNavigation(navSolutions, settings)
//Functions plots variations of coordinates over time and a 3D position
//plot. It plots receiver coordinates in UTM system or coordinate offsets if
//the true UTM receiver coordinates are provided.  
//
//plotNavigation(navSolutions, settings)
//
//   Inputs:
//       navSolutions    - Results from navigation solution function. It
//                       contains measured pseudoranges and receiver
//                       coordinates.
//       settings        - Receiver settings. The true receiver coordinates
//                       are contained in this structure.

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

  // Plot results in the necessary data exists ==============================
  if (~isempty(navSolutions))

    // If reference position is not provided, then set reference position
    // to the average postion
    if isnan(settings.truePosition.E) | isnan(settings.truePosition.N) ...
                                      | isnan(settings.truePosition.U)

      //=== Compute mean values ========================================== 
      // Remove NaN-s or the output of the function MEAN will be NaN.
      refCoord.E = mean(navSolutions.E(~isnan(navSolutions.E)));
      refCoord.N = mean(navSolutions.N(~isnan(navSolutions.N)));
      refCoord.U = mean(navSolutions.U(~isnan(navSolutions.U)));

      //Also convert geodetic coordinates to deg:min:sec vector format
      meanLongitude = dms2mat(deg2dms(...
          mean(navSolutions.longitude(~isnan(navSolutions.longitude)))), -5);    
      meanLatitude  = dms2mat(deg2dms(...
          mean(navSolutions.latitude(~isnan(navSolutions.latitude)))), -5);

      refPointLgText = strcat(["$\large Mean Position:", " Lat: ", ...
                              string(meanLatitude(1)), "^{\circ}", ...
                              string(meanLatitude(2)), "^{\prime}", ...
                              string(meanLatitude(3)), "^{\prime\prime} ", ...
                              "  Lng: ", ...
                              string(meanLongitude(1)), "^{\circ}", ...
                              string(meanLongitude(2)), "^{\prime}", ...
                              string(meanLongitude(3)), "^{\prime\prime} ", ...
                              "  Hgt: ", ...
                              string(mean(navSolutions.height(~isnan(navSolutions.height)))),...
                              "m $"]);
    else
      refPointLgText = 'Reference Position';
      refCoord.E = settings.truePosition.E;
      refCoord.N = settings.truePosition.N;
      refCoord.U = settings.truePosition.U;        
    end    
     
    figureNumber = 300;
    // The 300 is chosen for more convenient handling of the open
    // figure windows, when many figures are closed and reopened. Figures
    // drawn or opened by the user, will not be "overwritten" by this
    // function if the auto numbering is not used.
 
    //=== Select (or create) and clear the figure ==========================
    figure(figureNumber, "Figure_name", "Navigation solutions");
    clf   (figureNumber);

    // Plot all figures =======================================================
 
    //--- Coordinate differences in UTM system -----------------------------
    subplot(2,1,1);
    plot((navSolutions.E - refCoord.E)', 'blue' );
    plot((navSolutions.N - refCoord.N)', 'green');
    plot((navSolutions.U - refCoord.U)', 'red'  );

    legend('E', 'N', 'U');
    xtitle('Coordinates variations in UTM system', ...
           strcat(['Measurement period: ', string(settings.navSolPeriod), 'ms']), ...
           'Variations (m)');
 
    //--- Position plot in UTM system --------------------------------------
    subplot(2,2,3);
    param3d1(navSolutions.E - refCoord.E, ...
             navSolutions.N - refCoord.N, ...
             list(navSolutions.U - refCoord.U, -5));
    //Plot the reference point
    
    param3d1(0, 0, list(0,-4))
    
    legend('Measurements', refPointLgText);
    xtitle('Positions in UTM system (3D plot)', 'East (m)', 'North (m)', 'Upping (m)');

    //--- Satellite sky plot -----------------------------------------------
    subplot(2,2,4);
    plot2d(0,0,-1,"010"," ",[-100,-100,100,100]);
    //xtitle('Sky plot');
    xtitle (strcat(['Sky plot (mean PDOP: ', string(mean(navSolutions.DOP(2,:))), ')']));
    xrect(-90,90,180,180)
    
    th = (1:6) * 2*%pi / 12;
    cst = cos(th); 
    snt = sin(th);
    cs = 90*[cst; -cst];
    sn = 90*[snt; -snt];
    xpoly(sn(1:2), cs(1:2));
    xpoly(sn(3:4), cs(3:4));
    xpoly(sn(5:6), cs(5:6));
    xpoly(sn(7:8), cs(7:8));
    xpoly(sn(9:10), cs(9:10));
    xpoly(sn(11:12), cs(11:12));
    
    th = 0 : %pi/50 : 2*%pi;
    xunit = cos(th);
    yunit = sin(th);
    xpoly(0*15*xunit, 0*15*yunit);
    xpoly(1*15*xunit, 1*15*yunit);
    xpoly(2*15*xunit, 2*15*yunit);
    xpoly(3*15*xunit, 3*15*yunit);
    xpoly(4*15*xunit, 4*15*yunit);
    xpoly(5*15*xunit, 5*15*yunit);
    xpoly(6*15*xunit, 6*15*yunit);
    
    elSpherical = 90*cos(navSolutions.channel.el * %pi/180);
    
    yy = elSpherical .* cos(navSolutions.channel.az * %pi/180);
    xx = elSpherical .* sin(navSolutions.channel.az * %pi/180);
    
    for t = 1:length(xx)
      plot2d(xx(t),yy(t),-4,"010"," ",[-100,-100,100,100]);
    end
    
  else
    disp('plotNavigation: No navigation data to plot.');
  end // if (~isempty(navSolutions))

endfunction
