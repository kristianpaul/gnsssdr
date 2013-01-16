function [eph, t] = ephemeris(data)
//Function decodes ephemerides and time of frame start from the given bit 
//stream. The stream (array) in the parameter DATA must contain 30000 bits. 
//The first element in the array must be the first bit of a string. The 
//string number of the first string in the array is not important.
//
//Function does not check parity!
//
//[eph, t] = ephemeris(data)
//
//   Inputs:
//       data        - limited to +-1 prompt correlator output.
//   Outputs:
//       t           - Time Of frame start of the first string (in seconds)
//       eph         - SV ephemeris
//--------------------------------------------------------------------------
// Written by Artyom Gavrilov
//--------------------------------------------------------------------------

  if length(data)<30000
    error('The data array must contain 30000 bits (30 seconds of data)!!!)');
  end
  
  // Pi used in the BeiDou coordinate system
  BDPi = 3.1415926535898; 
  
  //Decode 5 data words!
  for i=1:5
    curr_sbfrm = data(6000*(i-1)+1 : 6000*(i-1)+6000);//Take 6000 samples 
                                              //wich correspond to 10 data words

    decoded_sbfrm = decode_bd_data(curr_sbfrm); //bits er in the form: "0" - "-1", 
                                                //"1" - "+1".
    decoded_sbfrm = (decoded_sbfrm+1) / 2;        //convert "-1"/"+1" bits to "0"/"1".
    
    wrong_bits = find(decoded_sbfrm==0.5);      //This check is important for the case
    if ~isempty(wrong_bits) then                //of weak signals or signal lost.
      continue; //goto next loop iteration.     //Later in postnavigation
    end                                         //this sattelite will be excluded from processing.

    sbfrm_num = bin2dec(  strcat( dec2bin(decoded_sbfrm(5:7)) )  );
    //pause;
    select sbfrm_num
      case 1 then  //subframe №1.
        eph.SatH1     = decoded_sbfrm(28);///
        eph.IODC      = bin2dec(  strcat( dec2bin(decoded_sbfrm(29:33)) )  );
        eph.URAI      = bin2dec(  strcat( dec2bin(decoded_sbfrm(34:37)) )  );///
        eph.WN        = bin2dec(  strcat( dec2bin(decoded_sbfrm(38:50)) )  );///
        eph.t_oc      = bin2dec(  strcat( dec2bin(decoded_sbfrm(51:67)) )  ) * 2^3;///[s]
        eph.T_GD_1    = (bin2dec(  strcat( dec2bin(decoded_sbfrm(68:77)) )  )-..
                        (decoded_sbfrm(68))*2^(length(decoded_sbfrm(68:77))) ) * 0.1*10^-9;///[s]
        eph.alpha0    = (bin2dec(  strcat( dec2bin(decoded_sbfrm(88:95)) )  ) -..
                        (decoded_sbfrm(88))*2^(length(decoded_sbfrm(88:95))) ) * 2^(-30);///[s];
        eph.alpha1    = (bin2dec(  strcat( dec2bin(decoded_sbfrm(96:103)) )  )-..
                        (decoded_sbfrm(96))*2^(length(decoded_sbfrm(96:103))) ) * 2^(-27);///[s/pi];
        eph.alpha2    = (bin2dec(  strcat( dec2bin(decoded_sbfrm(104:111)) )  )-..
                        (decoded_sbfrm(104))*2^(length(decoded_sbfrm(104:111))) ) * 2^(-24);///[s/pi^2];
        eph.alpha3    = (bin2dec(  strcat( dec2bin(decoded_sbfrm(112:119)) )  )-..
                        (decoded_sbfrm(88))*2^(length(decoded_sbfrm(88:95))) ) * 2^(-24);///[s/pi^3];
        eph.beta0     = (bin2dec(  strcat( dec2bin(decoded_sbfrm(120:127)) )  )-..
                        (decoded_sbfrm(120))*2^(length(decoded_sbfrm(120:127))) ) * 2^(11);///[s];
        eph.beta1     = (bin2dec(  strcat( dec2bin(decoded_sbfrm(128:135)) )  )-..
                        (decoded_sbfrm(120))*2^(length(decoded_sbfrm(120:127))) ) * 2^(14);///[s/pi];
        eph.beta2     = (bin2dec(  strcat( dec2bin(decoded_sbfrm(136:143)) )  )-..
                        (decoded_sbfrm(136))*2^(length(decoded_sbfrm(136:143))) ) * 2^(16);///[s/pi^2];
        eph.beta3     = (bin2dec(  strcat( dec2bin(decoded_sbfrm(144:151)) )  )-..
                        (decoded_sbfrm(144))*2^(length(decoded_sbfrm(144:151))) ) * 2^(16);///[s/pi^3];
        eph.a2        = (bin2dec(  strcat( dec2bin(decoded_sbfrm(152:162)) )  )-..
                        (decoded_sbfrm(152))*2^(length(decoded_sbfrm(152:162))) ) * 2^(-66);///[s/s^2];
        eph.a0        = (bin2dec(  strcat( dec2bin(decoded_sbfrm(163:186)) )  )-..
                        (decoded_sbfrm(163))*2^(length(decoded_sbfrm(163:186))) ) * 2^(-33);///[s];
        eph.a1        = (bin2dec(  strcat( dec2bin(decoded_sbfrm(187:208)) )  )-..
                        (decoded_sbfrm(187))*2^(length(decoded_sbfrm(187:208))) ) * 2^(-50);///[s/s];
        eph.IODE      = bin2dec(  strcat( dec2bin(decoded_sbfrm(209:213)) )  );
      case 2 then //subframe №2.
        eph.deltan    = (bin2dec(  strcat( dec2bin(decoded_sbfrm(28:43)) )  )-..
                        (decoded_sbfrm(28))*2^(length(decoded_sbfrm(28:43))) ) * 2^(-43) * BDPi;///[pi/s]->[1/s]
        eph.C_uc      = (bin2dec(  strcat( dec2bin(decoded_sbfrm(44:61)) )  )-..
                        (decoded_sbfrm(44))*2^(length(decoded_sbfrm(44:61))) ) * 2^(-31);///[rad]
        eph.M_0       = (bin2dec(  strcat( dec2bin(decoded_sbfrm(62:93)) )  )-..
                        (decoded_sbfrm(62))*2^(length(decoded_sbfrm(62:93))) ) * 2^(-31) * BDPi;///[pi]->[-]
        eph.e         = (bin2dec(  strcat( dec2bin(decoded_sbfrm(94:125)) )  )-..
                        (decoded_sbfrm(94))*2^(length(decoded_sbfrm(94:125))) ) * 2^(-33);///[-]
        eph.C_us      = (bin2dec(  strcat( dec2bin(decoded_sbfrm(126:143)) )  )-..
                        (decoded_sbfrm(126))*2^(length(decoded_sbfrm(126:143))) ) * 2^(-31);///[rad]
        eph.C_rc      = (bin2dec(  strcat( dec2bin(decoded_sbfrm(144:161)) )  )-..
                        (decoded_sbfrm(144))*2^(length(decoded_sbfrm(144:161))) ) * 2^(-6);///[m]
        eph.C_rs      = (bin2dec(  strcat( dec2bin(decoded_sbfrm(162:179)) )  )-..
                        (decoded_sbfrm(162))*2^(length(decoded_sbfrm(162:179))) ) * 2^(-6);///[m]
        eph.sqrtA     = bin2dec(  strcat( dec2bin(decoded_sbfrm(180:211)) )  ) * 2^(-19);///[m^(1/2)]
        eph.t_oe_msb  = bin2dec(  strcat( dec2bin(decoded_sbfrm(212:213)) )  ) * 2^(15) * 2^(3);///[s]
      case 3 then //subframe №3.
        eph.t_oe_lsb  = bin2dec(  strcat( dec2bin(decoded_sbfrm(28:42)) )  ) * 2^(3);///[s]
        eph.i_0       = (bin2dec(  strcat( dec2bin(decoded_sbfrm(43:74)) )  )-..
                        (decoded_sbfrm(43))*2^(length(decoded_sbfrm(43:74))) ) * 2^(-31) * BDPi;///[pi]->[-]
        eph.C_ic      = (bin2dec(  strcat( dec2bin(decoded_sbfrm(75:92)) )  )-..
                        (decoded_sbfrm(75))*2^(length(decoded_sbfrm(75:92))) ) * 2^(-31);///[rad]
        eph.omegaDot  = (bin2dec(  strcat( dec2bin(decoded_sbfrm(93:116)) )  )-..
                        (decoded_sbfrm(93))*2^(length(decoded_sbfrm(93:116))) ) * 2^(-43) * BDPi;///[pi/s]->[1/s]
        eph.C_is      = (bin2dec(  strcat( dec2bin(decoded_sbfrm(117:134)) )  )-..
                        (decoded_sbfrm(117))*2^(length(decoded_sbfrm(117:134))) ) * 2^(-31);///[rad]
        eph.iDot      = (bin2dec(  strcat( dec2bin(decoded_sbfrm(135:148)) )  )-..
                        (decoded_sbfrm(135))*2^(length(decoded_sbfrm(135:148))) ) * 2^(-43) * BDPi;///[pi/s]-> [1/s]
        eph.omega_0   = (bin2dec(  strcat( dec2bin(decoded_sbfrm(149:180)) )  )-..
                        (decoded_sbfrm(149))*2^(length(decoded_sbfrm(149:180))) ) * 2^(-31) * BDPi;///[pi]
        eph.omega     = (bin2dec(  strcat( dec2bin(decoded_sbfrm(181:212)) )  )-..
                        (decoded_sbfrm(181))*2^(length(decoded_sbfrm(181:212))) ) * 2^(-31) * BDPi;///[pi]
      case 4 then //subframe №4.
      case 5 then //subframe #5.
    end

  end

  eph.t_oe = eph.t_oe_msb + eph.t_oe_lsb; //Surprise from BeiDou ;)
  
  t = bin2dec(  strcat( dec2bin(decoded_sbfrm(8:27)) )  ) - 30;
endfunction 
