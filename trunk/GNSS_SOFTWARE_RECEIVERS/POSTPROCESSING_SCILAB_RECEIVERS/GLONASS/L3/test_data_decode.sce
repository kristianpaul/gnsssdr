//Extract navigation data samples:
trkRslt_I_P = sign(trackResults.I_P(1:$)); //pilot-channel.
trkRslt_Q_P = sign(trackResults.Q_P2(1:$)); //data-channel.

//Plot data
figure;
plot2d(trkRslt_I_P, rect=[0, -1.5, length(trackResults.I_P), 1.5], style=[color("blue")]);
plot2d(trkRslt_Q_P, rect=[0, -1.5, length(trackResults.I_P), 1.5], style=[color("red")]);
xtitle('Correlators outputs (sign(Ip), sign(Qp))', 'time [ms]','bit');
xgrid();
// Format plot:
a=get("current_axes");
a.labels_font_size=3; a.children.children.thickness=3;
t=a.title; t.foreground=9; t.font_size=3;
a1=a.x_label; a1.font_size=3;
a2=a.y_label; a2.font_size=3;

// Find Neuman-Hoffman code start:
NH_pilot  = [-1 -1 -1 -1 1 1 -1 1 -1 1]; //Neuman-Hoffman code;
BK_data   = [-1 -1 -1 1 -1];             //Barker code;
corr_NH_trkRslt_I_P = abs(xcorr(trkRslt_I_P, NH_pilot));
NH_pilot_start = find( corr_NH_trkRslt_I_P(size(trkRslt_I_P,2):$) == 10 );

// Cut from the first beginning of the Neuman-Hoffman code:
trkRslt_I_P = trkRslt_I_P(NH_pilot_start(1):$);
trkRslt_Q_P = trkRslt_Q_P(NH_pilot_start(1):$);

// Correct the sign, if necessary:
if (sum(NH_pilot.*trkRslt_I_P(1:length(NH_pilot))) == -20) then
  trkRslt_I_P = -trkRslt_I_P;
  trkRslt_Q_P = -trkRslt_Q_P;
end

// Take data bits as multiple of 10:
trkRslt_I_P = trkRslt_I_P(1 : 10*floor(length(trkRslt_I_P)/10));
trkRslt_Q_P = trkRslt_Q_P(1 : 10*floor(length(trkRslt_Q_P)/10));

//make duration of the sequences the same as data length^:
BK_data  = repmat(BK_data,  1, 2*floor(length(trkRslt_I_P)/10));
NH_pilot = repmat(NH_pilot, 1,   floor(length(trkRslt_Q_P)/10));

//wipe of Barker code and Neuman-Hoffman code from input data:
trkRslt_I_P = trkRslt_I_P .* NH_pilot;
trkRslt_Q_P = trkRslt_Q_P .* BK_data;

//Plot result data:
figure;
plot2d(trkRslt_Q_P, rect=[0, -1.5, length(trkRslt_Q_P), 1.5], style=[color("blue")]);
xtitle('Information channel after Barker code wipe of', 'time [ms]','bit');
xgrid();
//Format plot:
a=get("current_axes");
a.labels_font_size=3; a.children.children.thickness=3;
t=a.title; t.foreground=9; t.font_size=3;
a1=a.x_label; a1.font_size=3;
a2=a.y_label; a2.font_size=3;

figure;
plot2d(trkRslt_I_P, rect=[0, -1.5, length(trackResults.I_P), 1.5], style=[color("blue")]);
xtitle('Pilot channel outputs after Neuman-Hoffman code wioe of', 'time [ms]','bit');
xgrid();
//Format plot:
a=get("current_axes");
a.labels_font_size=3; a.children.children.thickness=3;
t=a.title; t.foreground=9; t.font_size=3;
a1=a.x_label; a1.font_size=3;
a2=a.y_label; a2.font_size=3;

// Decode data:
//1) Resample data from 1000bit/sec to 200 bit-sec:
ndata = matrix(trkRslt_Q_P, 5, (length(trkRslt_Q_P) / 5));
ndata = sum(ndata, 'r');
ndata = sign(ndata);

//2) Convolutional decoder:
n = 2;                             //coder rate;
m = 7;                             //coder constraint length;
x = [1 0 1 1 0 1 1;1 1 1 1 0 0 1]; //coder polynomial;
decoded_data = convol_decoder(floor((ndata+1)/2), n, m, x); 

//Find Time Marks:
tm_bits = [-1 -1 -1 -1 -1 1 -1 -1 1 -1 -1 1 -1 1 -1 -1 1 1 1 -1]; //GLONASS L3 timemark
corr_tm = abs(xcorr((decoded_data*2-1), tm_bits));
figure;
plot2d(corr_tm(length(decoded_data):$), ..
            rect=[0, -1.5, 10+length(decoded_data), 25], style=[color("blue")]);
xtitle('Time marks correspond to peaks with amplitude=20', 'time [10*ms]',..
       'Correlatiob function amplitude');
xgrid();
//Format plot:
a=get("current_axes");
a.labels_font_size=3; a.children.children.thickness=3;
t=a.title; t.foreground=9; t.font_size=3;
a1=a.x_label; a1.font_size=3;
a2=a.y_label; a2.font_size=3;
