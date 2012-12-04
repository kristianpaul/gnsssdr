function [satPositions, satVelocities, satAccelerations, satTransmitTime, satClkCorr] = satposg(transmitTime, prnList, eph)
//Function calculates initial position, velocity and acceleration
// of the satellites in prnList on the transmitTime based on
// ephemeris data (eph).
//
//[satPositions, satVelocities, satAccelerations, satTransmitTime, satClkCorr] = satposg(transmitTime, prnList, eph)
//
//   Inputs:
//       transmitTime        - time at which satellite position is calculated
//       prnList             - list of satellites
//       eph                 - satellites ephemeris
//   Outputs:
//       satPositions        - satellites positions
//       satVelocities       - satellites velocities
//       satAccelerations    - satellites accelerations
//       satTransmitTime     - delta time (time between ephemeris isue time and transmitTime)
//       satClkCorr          - corrections for satellite clock
//--------------------------------------------------------------------------
// Written by Artyom Gavrilov for scilab 5.3.0
// Idea is taken from "CALCULATIONS FORPOSITIONING WITH THE GLOBAL NAVIGATION SATELLITE SYSTEM"
// by Chao-heh Cheng, august 1998 (Ohio University)
//--------------------------------------------------------------------------

  numOfSatellites = length(prnList);
  // Initialize results =========================================================
  satClkCorr   =    zeros(1, numOfSatellites);
  satPositions =    zeros(3, numOfSatellites);
  satVelocities =   zeros(3, numOfSatellites);
  satTransmitTime = zeros(1, numOfSatellites);
  // Process each satellite =====================================================

  for satNr = 1 : numOfSatellites

    prn = prnList(satNr);

    //Delta time between ephemeris issue time and current time.
    ///deltat = (transmitTime*1000) - (eph(prn).tb * 60 * 1000); 
    deltat = (transmitTime(prn)*1000) - (eph(prn).tb * 60 * 1000);
    //To speed up calculations we split satpos calculations is subintervals.
    deltat10    = fix(deltat/10000);
    remdeltat10 = deltat - fix(deltat/10000)*10000;
    deltat1     = fix(remdeltat10 / 1000);
    remdeltat1  = remdeltat10 - fix(remdeltat10/1000)*1000;
    deltat001   = remdeltat1;


    //Constants:
    mu  = 398600.44e9;
    c20 = -1082.63e-6;
    ae  = 6378.136e3;
    we  = 0.7292115e-4;

    //Calculations:
    w10 = eph(prn).x * 1000;
    w20 = eph(prn).y * 1000;
    w30 = eph(prn).z * 1000;
    w40 = eph(prn).xdot * 1000;
    w50 = eph(prn).ydot * 1000;
    w60 = eph(prn).zdot * 1000;
    xdotdot = eph(prn).xdotdot * 1000;
    ydotdot = eph(prn).ydotdot * 1000;
    zdotdot = eph(prn).zdotdot * 1000;

    h = 10 * sign(deltat);//10sec inegration step.
    for i=1:abs(deltat10)

      r = sqrt( (w10^2) + (w20^2) + (w30^2) );

      k11 = h*(w40);
      k12 = h*(w50);
      k13 = h*(w60);
      k14 = h*(-mu/(r^3)*w10 + ...
            3/2*c20*mu*(ae^2)/(r^5)*w10*(1 - 5/(r^2)*(w30^2)) + ...
            (we^2)*w10 + 2*we*w50 + xdotdot);
      k15 = h*(-mu/(r^3)*w20 + ...
            3/2*c20*mu*(ae^2)/(r^5)*w20*(1 - 5/(r^2)*(w30^2)) + ...
            (we^2)*w20 - 2*we*w40 + ydotdot);
      k16 = h*(-mu/(r^3)*w30 + ...
            3/2*c20*mu*(ae^2)/(r^5)*w30*(3 - 5/(r^2)*(w30^2)) + ...
            zdotdot);

      k21 = h*(w40+0.5*k14);
      k22 = h*(w50+0.5*k15);
      k23 = h*(w60+0.5*k16);
      k24 = h*(-mu/(r^3)*(w10+0.5*k11) + ...
            3/2*c20*mu*(ae^2)/(r^5)*(w10+0.5*k11) * ...
            (1-5/(r^2)*(w30+0.5*k13)^2) + ...
            (we^2)*(w10+0.5*k11) + 2*we*(w50+0.5*k15) + xdotdot);
      k25 = h*(-mu/(r^3)*(w20+0.5*k12) + ...
            3/2*c20*mu*(ae^2)/(r^5)*(w20+0.5*k12) * ...
            (1-5/(r^2)*(w30+0.5*k13)^2) + ...
            (we^2)*(w20+0.5*k12) - 2*we*(w40+0.5*k14) + ydotdot);
      k26 = h*(-mu/(r^3)*(w30+0.5*k13) + ...
            3/2*c20*mu*(ae^2)/(r^5)*(w30+0.5*k13) * ...
            (3-5/(r^2)*((w30+0.5*k13)^2)) + ...
            zdotdot);

      k31 = h*(w40+0.5*k24);
      k32 = h*(w50+0.5*k25);
      k33 = h*(w60+0.5*k26);
      k34 = h*(-mu/(r^3)*(w10+0.5*k21) + ...
            3/2*c20*mu*(ae^2)/(r^5)*(w10+0.5*k21) * ...
            (1-5/(r^2)*(w30+0.5*k23)^2) + ...
            (we^2)*(w10+0.5*k21) + 2*we*(w50+0.5*k25) + xdotdot);
      k35 = h*(-mu/(r^3)*(w20+0.5*k22) + ...
            3/2*c20*mu*(ae^2)/(r^5)*(w20+0.5*k22) * ...
            (1-5/(r^2)*(w30+0.5*k23)^2) + ...
            (we^2)*(w20+0.5*k22) - 2*we*(w40+0.5*k24) + ydotdot);
      k36 = h*(-mu/(r^3)*(w30+0.5*k23) + ...
            3/2*c20*mu*(ae^2)/(r^5)*(w30+0.5*k23) * ...
            (3-5/(r^2)*((w30+0.5*k23)^2)) + ...
            zdotdot);

      k41 = h*(w40+k34);
      k42 = h*(w50+k35);
      k43 = h*(w60+k36);
      k44 = h*(-mu/(r^3)*(w10+k31) + 3/2*c20*mu*(ae^2)/(r^5)*(w10+k31) * ...
            (1-5/(r^2)*((w30+k33)^2)) + (we^2)*(w10+k31) + ...
            2*we*(w50+k35) + xdotdot);
      k45 = h*(-mu/(r^3)*(w20+k32) + 3/2*c20*mu*(ae^2)/(r^5)*(w20+k32) * ...
            (1-5/(r^2)*((w30+k33)^2)) + (we^2)*(w20+k32) - ...
            2*we*(w40+k34) + ydotdot);
      k46 = h*(-mu/(r^3)*(w30+k33) + 3/2*c20*mu*(ae^2)/(r^5)*(w30+k33) * ...
            (3-5/(r^2)*((w30+k33)^2)) + ...
            zdotdot);

      w11 = w10 + 1/6*(k11 + 2*k21 + 2*k31 + k41);
      w21 = w20 + 1/6*(k12 + 2*k22 + 2*k32 + k42);
      w31 = w30 + 1/6*(k13 + 2*k23 + 2*k33 + k43);
      w41 = w40 + 1/6*(k14 + 2*k24 + 2*k34 + k44);
      w51 = w50 + 1/6*(k15 + 2*k25 + 2*k35 + k45);
      w61 = w60 + 1/6*(k16 + 2*k26 + 2*k36 + k46);

      w10 = w11;
      w20 = w21;
      w30 = w31;
      w40 = w41;
      w50 = w51;
      w60 = w61;
    end

    h = 1 * sign(deltat);//1sec integration step.
    for i=1:abs(deltat1)

      r = sqrt( (w10^2) + (w20^2) + (w30^2) );

      k11 = h*(w40);
      k12 = h*(w50);
      k13 = h*(w60);
      k14 = h*(-mu/(r^3)*w10 + ...
            3/2*c20*mu*(ae^2)/(r^5)*w10*(1 - 5/(r^2)*(w30^2)) + ...
            (we^2)*w10 + 2*we*w50 + xdotdot);
      k15 = h*(-mu/(r^3)*w20 + ...
            3/2*c20*mu*(ae^2)/(r^5)*w20*(1 - 5/(r^2)*(w30^2)) + ...
            (we^2)*w20 - 2*we*w40 + ydotdot);
      k16 = h*(-mu/(r^3)*w30 + ...
            3/2*c20*mu*(ae^2)/(r^5)*w30*(3 - 5/(r^2)*(w30^2)) + ...
            zdotdot);

      k21 = h*(w40+0.5*k14);
      k22 = h*(w50+0.5*k15);
      k23 = h*(w60+0.5*k16);
      k24 = h*(-mu/(r^3)*(w10+0.5*k11) + ...
            3/2*c20*mu*(ae^2)/(r^5)*(w10+0.5*k11) * ...
            (1-5/(r^2)*(w30+0.5*k13)^2) + ...
            (we^2)*(w10+0.5*k11) + 2*we*(w50+0.5*k15) + xdotdot);
      k25 = h*(-mu/(r^3)*(w20+0.5*k12) + ...
            3/2*c20*mu*(ae^2)/(r^5)*(w20+0.5*k12) * ...
            (1-5/(r^2)*(w30+0.5*k13)^2) + ...
            (we^2)*(w20+0.5*k12) - 2*we*(w40+0.5*k14) + ydotdot);
      k26 = h*(-mu/(r^3)*(w30+0.5*k13) + ...
            3/2*c20*mu*(ae^2)/(r^5)*(w30+0.5*k13) * ...
            (3-5/(r^2)*((w30+0.5*k13)^2)) + ...
            zdotdot);

      k31 = h*(w40+0.5*k24);
      k32 = h*(w50+0.5*k25);
      k33 = h*(w60+0.5*k26);
      k34 = h*(-mu/(r^3)*(w10+0.5*k21) + ...
            3/2*c20*mu*(ae^2)/(r^5)*(w10+0.5*k21) * ...
            (1-5/(r^2)*(w30+0.5*k23)^2) + (we^2)*(w10+0.5*k21) + ...
            2*we*(w50+0.5*k25) + xdotdot);
      k35 = h*(-mu/(r^3)*(w20+0.5*k22) + ...
            3/2*c20*mu*(ae^2)/(r^5)*(w20+0.5*k22) * ...
            (1-5/(r^2)*(w30+0.5*k23)^2) + (we^2)*(w20+0.5*k22) - ...
            2*we*(w40+0.5*k24) + ydotdot);
      k36 = h*(-mu/(r^3)*(w30+0.5*k23) + ...
            3/2*c20*mu*(ae^2)/(r^5)*(w30+0.5*k23) * ...
            (3-5/(r^2)*((w30+0.5*k23)^2)) + ...
            zdotdot);

      k41 = h*(w40+k34);
      k42 = h*(w50+k35);
      k43 = h*(w60+k36);
      k44 = h*(-mu/(r^3)*(w10+k31) + ...
            3/2*c20*mu*(ae^2)/(r^5)*(w10+k31) * ...
            (1-5/(r^2)*((w30+k33)^2)) + (we^2)*(w10+k31) + ...
            2*we*(w50+k35) + xdotdot);
      k45 = h*(-mu/(r^3)*(w20+k32) + ...
            3/2*c20*mu*(ae^2)/(r^5)*(w20+k32) * ...
            (1-5/(r^2)*((w30+k33)^2)) + (we^2)*(w20+k32) - ...
            2*we*(w40+k34) + ydotdot);
      k46 = h*(-mu/(r^3)*(w30+k33) + ...
            3/2*c20*mu*(ae^2)/(r^5)*(w30+k33) * ...
            (3-5/(r^2)*((w30+k33)^2)) + ...
            zdotdot);

      w11 = w10 + 1/6*(k11 + 2*k21 + 2*k31 + k41);
      w21 = w20 + 1/6*(k12 + 2*k22 + 2*k32 + k42);
      w31 = w30 + 1/6*(k13 + 2*k23 + 2*k33 + k43);
      w41 = w40 + 1/6*(k14 + 2*k24 + 2*k34 + k44);
      w51 = w50 + 1/6*(k15 + 2*k25 + 2*k35 + k45);
      w61 = w60 + 1/6*(k16 + 2*k26 + 2*k36 + k46);

      w10=w11;
      w20=w21;
      w30=w31;
      w40=w41;
      w50=w51;
      w60=w61;
    end

    h = 0.001 * sign(deltat);//1ms integration step.
    for i=1:abs(deltat001)

      r = sqrt( (w10^2) + (w20^2) + (w30^2) );

      k11 = h*(w40);
      k12 = h*(w50);
      k13 = h*(w60);
      k14 = h*(-mu/(r^3)*w10 + ...
            3/2*c20*mu*(ae^2)/(r^5)*w10*(1 - 5/(r^2)*(w30^2)) + ...
            (we^2)*w10 + 2*we*w50 + xdotdot);
      k15 = h*(-mu/(r^3)*w20 + ...
            3/2*c20*mu*(ae^2)/(r^5)*w20*(1 - 5/(r^2)*(w30^2)) + ...
            (we^2)*w20 - 2*we*w40 + ydotdot);
      k16 = h*(-mu/(r^3)*w30 + ...
            3/2*c20*mu*(ae^2)/(r^5)*w30*(3 - 5/(r^2)*(w30^2)) + ...
            zdotdot);

      k21 = h*(w40+0.5*k14);
      k22 = h*(w50+0.5*k15);
      k23 = h*(w60+0.5*k16);
      k24 = h*(-mu/(r^3)*(w10+0.5*k11) + ...
            3/2*c20*mu*(ae^2)/(r^5)*(w10+0.5*k11) * ...
            (1-5/(r^2)*(w30+0.5*k13)^2) + (we^2)*(w10+0.5*k11) + ...
            2*we*(w50+0.5*k15) + xdotdot);
      k25 = h*(-mu/(r^3)*(w20+0.5*k12) + ...
            3/2*c20*mu*(ae^2)/(r^5)*(w20+0.5*k12) * ...
            (1-5/(r^2)*(w30+0.5*k13)^2) + (we^2)*(w20+0.5*k12) - ...
            2*we*(w40+0.5*k14) + ydotdot);
      k26 = h*(-mu/(r^3)*(w30+0.5*k13) + ...
            3/2*c20*mu*(ae^2)/(r^5)*(w30+0.5*k13) * ...
            (3-5/(r^2)*((w30+0.5*k13)^2)) + zdotdot);

      k31 = h*(w40+0.5*k24);
      k32 = h*(w50+0.5*k25);
      k33 = h*(w60+0.5*k26);
      k34 = h*(-mu/(r^3)*(w10+0.5*k21) + ...
            3/2*c20*mu*(ae^2)/(r^5)*(w10+0.5*k21) * ...
            (1-5/(r^2)*(w30+0.5*k23)^2) + (we^2)*(w10+0.5*k21) + ...
            2*we*(w50+0.5*k25) + xdotdot);
      k35 = h*(-mu/(r^3)*(w20+0.5*k22) + ...
            3/2*c20*mu*(ae^2)/(r^5)*(w20+0.5*k22) * ...
            (1-5/(r^2)*(w30+0.5*k23)^2) + (we^2)*(w20+0.5*k22) - ...
            2*we*(w40+0.5*k24) + ydotdot);
      k36 = h*(-mu/(r^3)*(w30+0.5*k23) + ...
            3/2*c20*mu*(ae^2)/(r^5)*(w30+0.5*k23) * ...
            (3-5/(r^2)*((w30+0.5*k23)^2)) + zdotdot);

      k41 = h*(w40+k34);
      k42 = h*(w50+k35);
      k43 = h*(w60+k36);
      k44 = h*(-mu/(r^3)*(w10+k31) + 3/2*c20*mu*(ae^2)/(r^5)*(w10+k31) * ...
            (1-5/(r^2)*((w30+k33)^2)) + (we^2)*(w10+k31) + ...
            2*we*(w50+k35) + xdotdot);
      k45 = h*(-mu/(r^3)*(w20+k32) + 3/2*c20*mu*(ae^2)/(r^5)*(w20+k32) * ...
            (1-5/(r^2)*((w30+k33)^2)) + (we^2)*(w20+k32) - ...
            2*we*(w40+k34) + ydotdot);
      k46 = h*(-mu/(r^3)*(w30+k33) + 3/2*c20*mu*(ae^2)/(r^5)*(w30+k33) * ...
            (3-5/(r^2)*((w30+k33)^2)) + ...
            zdotdot);

      w11 = w10 + 1/6*(k11 + 2*k21 + 2*k31 + k41);
      w21 = w20 + 1/6*(k12 + 2*k22 + 2*k32 + k42);
      w31 = w30 + 1/6*(k13 + 2*k23 + 2*k33 + k43);
      w41 = w40 + 1/6*(k14 + 2*k24 + 2*k34 + k44);
      w51 = w50 + 1/6*(k15 + 2*k25 + 2*k35 + k45);
      w61 = w60 + 1/6*(k16 + 2*k26 + 2*k36 + k46);

      w10=w11;
      w20=w21;
      w30=w31;
      w40=w41;
      w50=w51;
      w60=w61;
    end

    satPositions(1, satNr)     = w10;
    satPositions(2, satNr)     = w20;
    satPositions(3, satNr)     = w30;
    satVelocities(1, satNr)    = w40;
    satVelocities(2, satNr)    = w50;
    satVelocities(3, satNr)    = w60;
    satAccelerations(1, satNr) = xdotdot;
    satAccelerations(2, satNr) = ydotdot;
    satAccelerations(3, satNr) = zdotdot;
    satTransmitTime            = deltat/1000;

    satClkCorr(satNr) = eph(prn).taun - eph(prn).gamman*(deltat/1000);

  end

endfunction
