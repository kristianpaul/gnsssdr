function [eph, t] = ephemeris(data)
//Function decodes ephemerides and time of frame start from the given bit 
//stream. The stream (array) in the parameter DATA must contain 31000 bits. 
//The first element in the array must be the first bit of a page. The 
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

  if length(data)<31000
    error('The data array must contain 31000 bits (31 seconds of data)!!!)');
  end
  
  // Pi used in the BeiDou coordinate system
  GLLPi = 3.1415926535898; 
  
  first_half_page = data(1:1000);

  decoded_first_half_page = decode_gll_data(first_half_page);
  
  //Decode x data pages!
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
      case 1 then  //page №1.
      case 2 then  //page №2.
      case 3 then  //page №3.
      case 4 then  //page №4.
    end

  end

  eph.t_oe = eph.t_oe_msb + eph.t_oe_lsb; //Surprise from BeiDou ;)
  
  t = bin2dec(  strcat( dec2bin(decoded_sbfrm(8:27)) )  ) - 30;
endfunction 
