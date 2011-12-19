clear;
clc;
stacksize('max');

exec('./include/generateCAcode.sci');

//------------Settings---------------------------------------------------------
fileName1 = 'e:\GavAI\GPS\scilab_convert_data\routines\file_read\FFF005.DAT';
fileType = 1;

f_rf = 1202.025e6; //[Hz] GLONASS L3 nominal frequency;
//f_if = 20.46e6;    //[Hz] IF nominal frequency;
//f_if = -2.025e6;    //[Hz] IF nominal frequency;
f_if = 12.00e6;    //[Hz] IF nominal frequency;
f_prn= 10.23e6;    //[Hz] Nominal PRN-generator clock frequency;
f_nh = 1e3;        //[Hz] Nominal Neiman-Huffman-generator clock frequency;
f_bk = 1e3;        //[Hz] Nominal Barker-generator clock frequency;
f_data = 0.2e3;    //[Hz] Nominal data-generator clock frequency (Data rate after convolutional coder);

k_car_prn  = f_rf / f_prn; //[unitless] Ratio between RF frequency and PRN clock freq;
k_car_nh   = f_rf / f_nh;  //[unitless] Ratio between RF frequency and NH clock freq;
k_car_bk   = f_rf / f_bk;  //[unitless] Ratio between RF frequency and BK clock freq;
k_car_data = f_rf / f_data;//[unitless] Ratio between RF frequency and data clock freq;

phi0_if   = 0;      //[rad] Initial phase of RF signal;
phi0_prn1 = 0;      //[rad] Initial phase of PRN signal;
phi0_prn2 = 0;      //[rad] Initial phase of PRN signal;
phi0_nh   = 0;      //[rad] Initial phase of NH signal;
phi0_bk   = 0;      //[rad] Initial phase of BK signal;
phi0_data = 0;      //[rad] Initial phase of data signal;

f_d = 2800;         //[Hz] Initial Doppler frequeny for RF-signal;
df  = -1.55;        //[Hz/sec] Initail Doppler frequency change rate for RF-signal;

//fs = 50.00e6;      //[Hz] Sampling frequency;
//fs = 24.00e6;      //[Hz] Sampling frequency;
fs = 48.00e6;      //[Hz] Sampling frequency;
ts = 1/fs;         //[sec]
T  = 4;            //[sec] Signal length to be generated;
T_elem = 10e-3;    //[sec] The smallest signal part to be generated.
T_parts = T/T_elem;//[unitless] On how many segments T will be divided.
dT = T / T_parts;  //[sec]

prn_num  = 30;      //PRN number;
prn_len  = 10230;   //[chips] PRN-code length in chips (bits);
nh_len   = 10;      //Heiman-Haffman code length in chips (bits);
bk_len   = 5;       //Barker-code length in chips (bits);
data_len = 24000;   //Navigation message length in bits (after convolutional coder); 
//data_len = 30000;     //possible value for future modernization;


//-----------Signal_generator--------------------------------------------------

t = ts : ts : T_elem; //time samples for generating signal of T_elem length;

PRN1 = generateCAcode(prn_num);            //Generate PRN-code for pilot-channel;
PRN2 = generateCAcode(prn_num + 32);       //Generate PRN-code for data-channel;
NH   = [-1 -1 -1 -1 1 1 -1 1 -1 1];        //Generate Neiman-Huffman-code for pilot-channel;
BK   = [-1 -1 -1 1 -1];                    //Generate Barker-code for data-channel;
DATA = (2 * round(rand(1, data_len))) - 1; // Temporary Stub for data bits after convolutional coder;

signal_I = [];
signal_Q = [];

[fd1, err1] = mopen(fileName1, 'wb');

for k=1:T_parts
    
    //Calculate phase for carrier;
    phi_if = (phi0_if) + (2*%pi*f_if*t) + ...
             (2*%pi*f_d*t) + ...
             ((2*%pi*df*t).*t);
    //phi0_if            - this is initial phase;
    //2*%pi*f_if*t       - this is phase change due to nominal frequency;
    //2*%pi*f_d*t        - this is phase change due to Doppler (f_d) frequency;
    //(2*%pi*df*t).*t    - this is phase change due to Change of Doppler (acceleration of the object);
    //t must be replaced by (t + (k-1)*T_elem)!
    //May be other parts should be added in future (like jerk and so on);
    phi_if = modulo(phi_if, (2*%pi));//Convert carrier phase to the range [0..2*pi];
    phi0_if = phi_if($);
    f_d = f_d + df*T_elem;
    
    //Calculate phase for PRN1;
    phi_prn1 = (phi0_prn1) + ((f_rf/k_car_prn)*t) + ...
              ( (f_d/k_car_prn)*t ) + ...// ( ((f_d/100)/k_car_prn)*t ) + ...
              ((( (df/k_car_prn) *t).*t));
    //The change in phase exactly the same like for carrier. The only 
    //difference is a special multiplier "k_car_prn".
    phi0_prn1 = modulo( phi_prn1($), prn_len );
    prn1_indx = (fix(   modulo(phi_prn1, prn_len)   ));
    
    //Calculate phase for PRN2;
    phi_prn2 = (phi0_prn2) + ((f_rf/k_car_prn)*t) + ...
              ( (f_d/k_car_prn)*t ) + ...
              ((( (df/k_car_prn) *t).*t));
    //The change in phase exactly the same like for carrier. The only 
    //difference is a special multiplier "k_car_prn".
    phi0_prn2 = modulo( phi_prn2($), prn_len );
    prn2_indx = (fix(   modulo(phi_prn2, prn_len)   ));
    
    //Calculte phase for Neiman-Huffman;
    phi_nh =  (phi0_nh) + ((f_rf/k_car_nh)*t) + ...
              ( (f_d/k_car_nh)*t ) + ...
              ((( (df/k_car_nh) *t).*t));
    phi0_nh = modulo( phi_nh($), nh_len );
    nh_indx = (fix(   modulo(phi_nh, nh_len)   ));
    
    //Calculate phase for Barker;
    phi_bk =  (phi0_bk) + ((f_rf/k_car_bk)*t) + ...
              ( (f_d/k_car_bk)*t ) + ...
              ((( (df/k_car_bk) *t).*t));
    phi0_bk = modulo(phi_bk($), bk_len);
    bk_indx = (fix(   modulo(phi_bk, bk_len)   ));
//    
    //Calculate phase for data-message;
    phi_data =  (phi0_data) + ((f_rf/k_car_data)*t) + ...
                ( (f_d/k_car_data)*t ) + ...
                ((( (df/k_car_data) *t).*t));
    phi0_data = modulo(phi_data($), data_len);
    data_indx = (fix(   modulo(phi_data, data_len)   ));
    
    //Generate carrier;
    carr_sin = sin(phi_if);    //generate carrier (I)
    carr_cos = cos(phi_if);    //generate carrier (Q)
    
    //Generate PRN;
    prn1 = PRN1(prn1_indx+1);    //generate PRN for I-channel;
    prn2 = PRN2(prn2_indx+1);    //generate PRN for Q-channel;
    
    //Generate NH;
    nh = NH(nh_indx+1);         //generate NH-code for pilot-channel;
    
    //Generate BK;
    bk = BK(bk_indx+1)
    
    //Generate DATA;
    data = DATA(data_indx+1);
    
    signal_I = ( (carr_sin .* prn1) .* nh );
    signal_Q = (  ( (carr_cos .* prn2) .* bk  )  .*  data  );
    
    signal_RSLT = (1/sqrt(2))*signal_I + (1/sqrt(2))*signal_Q;
    ///signal_RSLT(1:2:2*length(signal_I)-1) = signal_I;
    ///signal_RSLT(2:2:2*length(signal_Q)) = signal_Q;
    
    //Next step is to pass signal througn bandpass filter;
    
    //Next step is to write signal to file;
    signal_RSLT_r = (   round( (63.5 * signal_RSLT) + 63.5) * 2   ) - 127;
    ///signal_RSLT_r = (   round( (1.5 * signal_RSLT) + 1.5) * 2   ) - 3;
    mput( signal_RSLT_r, 'c', fd1);
    
end

mclose(fd1);

