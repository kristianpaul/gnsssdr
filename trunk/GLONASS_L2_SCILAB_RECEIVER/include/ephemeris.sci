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

  //Decode 15 data strings!
  string_1_pos = 0;//Used to detect first string number.
  for i=1:15
    curr_str = data(2000*(i-1)+1 : 2000*(i-1)+1700);//Take 1700 samples 
                                              //wich correspond to 85 data bits

    decoded_str = decode_gl_data(curr_str); //bits er in the form: "0" - "-1", 
                                            //"1" - "+1".
    decoded_str = (decoded_str +1) / 2;     //convert "-1"/"+1" bits to "0"/"1".

    str_num = bin2dec(  strcat( dec2bin(decoded_str(84:-1:81)) )  );
  
  // Only 5 first strings are of interest. The rest strings contain almanac that 
  // is not used in this program.
    select str_num
      case 1 then  //String №1.
        eph.P1        = bin2dec(  strcat( dec2bin(decoded_str(78:-1:77)) )  );
        eph.tk_h      = bin2dec(  strcat( dec2bin(decoded_str(76:-1:72)) )  );
        eph.tk_m      = bin2dec(  strcat( dec2bin(decoded_str(71:-1:66)) )  );
        eph.tk_s      = bin2dec(  strcat( dec2bin(decoded_str(65)      ) )  ) * 30;
        eph.xdot      = bin2dec(  strcat( dec2bin(decoded_str(63:-1:41)) )  ) * ((-1)^decoded_str(64)) * (2^-20);
        eph.xdotdot   = bin2dec(  strcat( dec2bin(decoded_str(39:-1:36)) )  ) * ((-1)^decoded_str(40)) * (2^-30);
        eph.x         = bin2dec(  strcat( dec2bin(decoded_str(34:-1:9 )) )  ) * ((-1)^decoded_str(35)) * (2^-11);
        string_1_pos = i;

      case 2 then //String №2.
        eph.Bn        = bin2dec(  strcat( dec2bin(decoded_str(80:-1:78)) )  );
        eph.P2        = bin2dec(  strcat( dec2bin(decoded_str(65)      ) )  );
        eph.tb        = bin2dec(  strcat( dec2bin(decoded_str(76:-1:70)) )  ) * 15;
        eph.ydot      = bin2dec(  strcat( dec2bin(decoded_str(63:-1:41)) )  ) * ((-1)^decoded_str(64)) * (2^-20);
        eph.ydotdot   = bin2dec(  strcat( dec2bin(decoded_str(39:-1:36)) )  ) * ((-1)^decoded_str(40)) * (2^-30);
        eph.y         = bin2dec(  strcat( dec2bin(decoded_str(34:-1:9 )) )  ) * ((-1)^decoded_str(35)) * (2^-11);

      case 3 then //String №3.
        eph.P3        = bin2dec(  strcat( dec2bin(decoded_str(80)      ) )  );
        eph.gamman    = bin2dec(  strcat( dec2bin(decoded_str(78:-1:69 )) )  ) * ((-1)^decoded_str(79)) * (2^-40);
        eph.P         = bin2dec(  strcat( dec2bin(decoded_str(67:-1:66)) )  );
        eph.In3       = bin2dec(  strcat( dec2bin(decoded_str(65)      ) )  );
        eph.zdot      = bin2dec(  strcat( dec2bin(decoded_str(63:-1:41)) )  ) * ((-1)^decoded_str(64)) * (2^-20);
        eph.zdotdot   = bin2dec(  strcat( dec2bin(decoded_str(39:-1:36)) )  ) * ((-1)^decoded_str(40)) * (2^-30);
        eph.z         = bin2dec(  strcat( dec2bin(decoded_str(34:-1:9 )) )  ) * ((-1)^decoded_str(35)) * (2^-11);

      case 4 then //String №4.
        eph.taun      = bin2dec(  strcat( dec2bin(decoded_str(79:-1:59 )) )  ) * ((-1)^decoded_str(80)) * (2^-30);
        eph.deltataun = bin2dec(  strcat( dec2bin(decoded_str(57:-1:54 )) )  ) * ((-1)^decoded_str(58)) * (2^-30);
        eph.En        = bin2dec(  strcat( dec2bin(decoded_str(53:-1:49)) )  );
        eph.P4        = bin2dec(  strcat( dec2bin(decoded_str(34)      ) )  );
        eph.Ft        = bin2dec(  strcat( dec2bin(decoded_str(33:-1:30)) )  );
        eph.Nt        = bin2dec(  strcat( dec2bin(decoded_str(26:-1:16)) )  );
        eph.n         = bin2dec(  strcat( dec2bin(decoded_str(15:-1:11)) )  );
        eph.M         = bin2dec(  strcat( dec2bin(decoded_str(10:-1:9 )) )  );
      case 5 then //String #5.
        eph.NA        = bin2dec(  strcat( dec2bin(decoded_str(80:-1:70)) )  );
        eph.tauc      = bin2dec(  strcat( dec2bin(decoded_str(68:-1:38)) )  ) * ((-1)^decoded_str(69)) * (2^-31);
        eph.N4        = bin2dec(  strcat( dec2bin(decoded_str(36:-1:32)) )  );
        eph.tauGPS    = bin2dec(  strcat( dec2bin(decoded_str(30:-1:10)) )  ) * ((-1)^decoded_str(31)) * (2^-30);
        eph.In5       = bin2dec(  strcat( dec2bin(decoded_str(9 )      ) )  );
    end

  end

  t = (eph.tk_h * 60 * 60) + (eph.tk_m * 60) + eph.tk_s; //Time of the frame 
  //start in 24-hour format is converted in the number of seconds since the 
  //day-start.

  t = t - ( (string_1_pos - 1)*2 ) - 0.3; //0.3 - time mark duration.

endfunction 
