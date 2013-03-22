// Code taken from RTKlib v2.4.2b11
// Copyright (C) 2010-2013 by T.TAKASU, All rights reserved.
// references :
//   [1] Global Navigation Satellite System GLONASS, Interface Control Document
//       Navigational radiosignal In bands L1, L2, (Edition 5.1), 2008
// SciLab version by Artyom Gavrilov, gnss-sdr.com
//=============================================================================
//=============================================================================
//=============================================================================
clear;clc;
//Constants declaration:
J2_GLO   = 1.0826257E-3; // 2nd zonal harmonic of geopot   ref [1]
MU_GLO   = 3.9860044E14; // gravitational constant         ref [1]
RE_GLO   = 6378136.0;    // radius of earth (m)            ref [1]
MU_GLO   = 3.9860044E14; // gravitational constant         ref [1]
OMGE_GLO = 7.292115E-5;  // earth angular velocity (rad/s) ref [1]
TSTEP    = 60.0;         // integration step glonass ephemeris (s)

// glonass orbit differential equations --------------------------------------
function [x, xdot, acc] = deq(x, xdot, acc)
  r2=sum(x(1:3).*x(1:3));
  r3=r2*sqrt(r2);
  omg2=OMGE_GLO^2;
  
  a=1.5*J2_GLO*MU_GLO*(RE_GLO^2)/r2/r3; // 3/2*J2*mu*Ae^2/r^5;
  b=5.0*x(3)*x(3)/r2;                   // 5*z^2/r^2;
  c=-MU_GLO/r3-a*(1.0-b);               // -mu/r^3-a(1-b);
  xdot(1)=x(4); xdot(2)=x(5); xdot(3)=x(6);
  xdot(4)=(c+omg2)*x(1)+2.0*OMGE_GLO*x(5)+acc(1);
  xdot(5)=(c+omg2)*x(2)-2.0*OMGE_GLO*x(4)+acc(2);
  xdot(6)=(c-2.0*a)*x(3)+acc(3);
endfunction

// glonass position and velocity by numerical integration --------------------
function [x, acc] = glorbit(t, x, acc)
    k1=[];k2=[];k3=[];k4=[];w=[];
    
    [x,k1,acc]=deq(x,k1,acc); for i=1:6 w(i)=x(i)+k1(i)*t/2.0;    end;
    [w,k2,acc]=deq(w,k2,acc); for i=1:6 w(i)=x(i)+k2(i)*t/2.0;    end;
    [w,k3,acc]=deq(w,k3,acc); for i=1:6 w(i)=x(i)+k3(i)*t;        end;
    [w,k4,acc]=deq(w,k4,acc);
    for i=1:6; x(i)=x(i)+(k1(i)+2.0*k2(i)+2.0*k3(i)+k4(i))*t/6.0; end;
endfunction

//==============================================================================
//Пример использования:

//I) Объявим вспомогательную функцию:
// функция вычисления координат и скоростей спутника на заданный момент времени
function [x, v, a] = satpos(x0, v0, a0, dt)
  t=dt; xx = [x0; v0]; aa = a0;

  tt=TSTEP;
  if dt<0 tt=-tt; end;
  
  if abs(t)<TSTEP tt=t; end
  [xx, aa] = glorbit(tt,xx,aa);
  while(abs(t)>1e-9)
    t=t-tt;
    if abs(t)<TSTEP tt=t; end
    [xx, aa] = glorbit(tt,xx,aa);
  end;
  
  x = xx(1:3); v = xx(4:6); a = aa(1:3);
endfunction

//=============================================================================
//Тестирование кода:
t = (6*60*60 + 30*60 + 0) - (6*60*60 + 15*60 + 0); //время относительно опорного времени эфемерид;

//Исходные данные из ИКД:
x(1)=-14081.752701*1000; x(2)=18358.958252*1000; x(3)=10861.302124*1000;
x(4)=-1.02576358*1000;   x(5)=1.08672147*1000;   x(6)=-3.15732343*1000;
acc(1)=0;                acc(2)=0;               acc(3)=0;

[xe,ve,ae]=satpos(x(1:3), x(4:6), acc(1:3), t);

printf("X=%f\tY=%f\tZ=%f\n",    xe(1)*0.001, xe(2)*0.001, xe(3)*0.001);
printf("Vx=%f\tVy=%f\tVz=%f\n", ve(1)*0.001, ve(2)*0.001, ve(3)*0.001);
