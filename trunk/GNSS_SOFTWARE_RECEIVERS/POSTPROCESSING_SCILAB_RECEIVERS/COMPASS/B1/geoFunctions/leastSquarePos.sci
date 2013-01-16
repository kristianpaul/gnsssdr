function [pos, el, az, dop] = leastSquarePos(satpos, obs, set_c, set_useTropCorr)
//Function calculates the Least Square Solution.
//
//[pos, el, az, dop] = leastSquarePos(satpos, obs, set_c, set_useTropCorr)
//
// Inputs:
// satpos - Satellites positions (in ECEF system: [X; Y; Z;] -
// one column per satellite)
// obs - Observations - the pseudorange measurements to each
// satellite:
// (e.g. [20000000 21000000 .... .... .... .... ....])
// set_c - setings.c
// set_useTropCorr - settings.useTropCorr
//
// Outputs:
// pos - receiver position and receiver clock error
// (in ECEF system: [X, Y, Z, dt])
// el - Satellites elevation angles (degrees)
// az - Satellites azimuth angles (degrees)
// dop - Dilutions Of Precision ([GDOP PDOP HDOP VDOP TDOP])
//-----------------------------------------------------------------------
// SoftGNSS v3.0
//-----------------------------------------------------------------------
// Based on Kai Borre
// Copyright (c) by Kai Borre
// Updated by Darius Plausinaitis, Peter Rinder and Nicolaj Bertelsen
// Updated and converted to scilab 5.3.0 by Artyom Gavrilov
// Updated by Gavrilov Denis 2012
//=======================================================================

//=== Initialization =====================================================
  nmbOfIterations = 7;

  dtr = %pi/180;
  pos = zeros(4, 1);
  nmbOfSatellites = size(obs,2);

  F = zeros(nmbOfSatellites, 1);
  A = zeros(nmbOfSatellites, 4);
  ///B = zeros(nmbOfSatellites, nmbOfSatellites);
  az = zeros(1, nmbOfSatellites);
  el = az;

//=== Iteratively find receiver position ===================================
  for iter = 1:nmbOfIterations

    for i = 1:nmbOfSatellites
      if iter == 1
        //--- Initialize variables at the first iteration --------------
        Rot_X = satpos(:, i);
        dist = sqrt((satpos(1, i) - pos(1))^2 + ...
        (satpos(2, i) - pos(2))^2 + ...
        (satpos(3, i) - pos(3))^2);
        trop = 0;
      else
        //--- Update equations -----------------------------------------
        rho2 = (satpos(1, i) - pos(1))^2 + (satpos(2, i) - pos(2))^2 + ...
               (satpos(3, i) - pos(3))^2;
        traveltime = sqrt(rho2) / set_c;
        //--- Correct satellite position (do to earth rotation) --------
        Rot_X = e_r_corr(traveltime, satpos(:, i));
        //--- Find the elevation angel of the satellite ----------------
        [az(i), el(i), dist] = topocent(pos(1:3, :), Rot_X - pos(1:3, :));

        if (set_useTropCorr == 1)
          //--- Calculate tropospheric correction --------------------
          trop = tropo(sin(el(i) * dtr), 0.0, 1013.0, 293.0, ...
                       50.0, 0.0, 0.0, 0.0);
        else
          trop = 0;
        end
      end
      F(i) = obs(i) - pos(4) - dist - trop;
      A(i, :) = [ (-(Rot_X(1) - pos(1))) / dist ...
                  (-(Rot_X(2) - pos(2))) / dist ...
                  (-(Rot_X(3) - pos(3))) / dist ...
                 1 ];
      ///B(i,i) = 1;
    end // for i = 1:nmbOfSatellites

    //--- Apply position update --------------------------------------------
    ///pos = pos + inv(A'*inv(B)*A)*A'*inv(B)*F;
    pos = pos + inv(A'*A)*A'*F;

  end // for iter = 1:nmbOfIterations

  pos = pos';

  //=== Calculate Dilution Of Precision ======================================
  //--- Initialize output ------------------------------------------------
  dop = zeros(1, 5);

  //--- Calculate DOP ----------------------------------------------------
  Q = inv(A'*A);

  dop(1) = sqrt(trace(Q));                  // GDOP
  dop(2) = sqrt(Q(1,1) + Q(2,2) + Q(3,3));  // PDOP
  dop(3) = sqrt(Q(1,1) + Q(2,2));           // HDOP
  dop(4) = sqrt(Q(3,3));                    // VDOP
  dop(5) = sqrt(Q(4,4));                    // TDOP

endfunction
