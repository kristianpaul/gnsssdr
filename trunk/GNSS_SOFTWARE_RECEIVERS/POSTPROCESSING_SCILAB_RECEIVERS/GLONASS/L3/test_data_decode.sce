//IMPORTANT NOTICE: The acquisition process is made in such a way that 
//Neiman-Hoffman sequence edge is detected during acquisition.
//That is why there is no need in aditional 
//search for Neiman-Hoffman sequence edge!

//Extract navigation data samples:
trkRslt_I_P  = sign(trackResults.I_P);  //pilot-channel.
trkRslt_Q_P2 = sign(trackResults.Q_P2); //data-channel.

//Plot data
figure;
plot2d(trkRslt_I_P, rect=[0, -1.5, length(trackResults.I_P), 1.5], style=[color("blue")]);
plot2d(trkRslt_Q_P2, rect=[0, -1.5, length(trackResults.I_P), 1.5], style=[color("red")]);
xtitle('Данные на выходе корреляторов (sign(Ip), sign(Qp))', 'время [мс]','бит');
xgrid();
// Format plot:
a=get("current_axes");
a.labels_font_size=3; a.children.children.thickness=3;
t=a.title; t.foreground=9; t.font_size=3;
a1=a.x_label; a1.font_size=3;
a2=a.y_label; a2.font_size=3;

// Take data bits as multiple of 10:
trkRslt_I_P_v2   = trkRslt_I_P(1 : 10*floor(length(trkRslt_I_P)/10));
trkRslt_Q_P2_v2  = trkRslt_Q_P2(1 : 10*floor(length(trkRslt_Q_P2)/10));

//prepare Barker-code sequence and Neiman-Hoffman sequence:
NH_pilot  = [-1 -1 -1 -1 1 1 -1 1 -1 1];
NH_pilot = [NH_pilot(2:10) NH_pilot(1)]; // Small Correction.
NH_data = [-1 -1 -1 1 -1];
NH_data = [NH_data(2:5) NH_data(1)];     // Small Correction.

//make duration of the sequences the same as data length^:
NH_data  = repmat(NH_data, 1, 2*floor(length(trkRslt_I_P)/10));
NH_pilot = repmat(NH_pilot, 1, floor(length(trkRslt_Q_P2)/10));

//wipe of Barker code and Neiman-Hoffman code from input data:
trkRslt_I_P_v3  = trkRslt_I_P_v2  .* NH_pilot;
trkRslt_Q_P2_v3 = trkRslt_Q_P2_v2 .* NH_data;
//trkRslt_I_P_v4  = trkRslt_I_P_v2  .* (-NH_pilot);
//trkRslt_Q_P2_v4 = trkRslt_Q_P2_v2 .* (-NH_data);

//Plot result data:
figure;
plot2d(trkRslt_Q_P2_v3, rect=[0, -1.5, length(trackResults.I_P), 1.5], style=[color("blue")]);
///plot2d(trkRslt_Q_P2, rect=[0, -1.5, length(trackResults.I_P), 1.5], style=[color("red")]);
///plot2d(NH_data, rect=[0, -1.5, length(trackResults.I_P), 1.5], style=[color("cyan")]);
xtitle('Данные информационного-канала после снятия кода Баркера', 'время [мс]','бит');
xgrid();
//Format plot:
a=get("current_axes");
a.labels_font_size=3; a.children.children.thickness=3;
t=a.title; t.foreground=9; t.font_size=3;
a1=a.x_label; a1.font_size=3;
a2=a.y_label; a2.font_size=3;

figure;
plot2d(trkRslt_I_P_v3, rect=[0, -1.5, length(trackResults.I_P), 1.5], style=[color("blue")]);
///plot2d(trkRslt_I_P, rect=[0, -1.5, length(trackResults.I_P), 1.5], style=[color("red")]);
///plot2d(NH_pilot, rect=[0, -1.5, length(trackResults.I_P), 1.5], style=[color("cyan")]);
xtitle('Данные пилот-канала после снятия кода Неймана-Хоффмана', 'время [мс]','бит');
xgrid();
//Format plot:
a=get("current_axes");
a.labels_font_size=3; a.children.children.thickness=3;
t=a.title; t.foreground=9; t.font_size=3;
a1=a.x_label; a1.font_size=3;
a2=a.y_label; a2.font_size=3;



//Time mark search (here time mark is written backward because convol instead of correlation is used to find it):
tm_bits = [-1 1 1 1 1 -1 -1 1 1 1 1 -1 -1 1 1 -1 1 1 1 -1 1 -1 -1 -1 1 1 1 -1];
tm_long = kron(-tm_bits, ones(1,5));

tm_corr_rslt = convol(tm_long, trkRslt_Q_P2_v3);
tm_corr_rslt = tm_corr_rslt(140:length(tm_corr_rslt)); //First 280 points are of no interest!
tm_corr_peak_indx = find( abs(tm_corr_rslt) > 130)'; //Find places where 
                                         // correlation-result is high 
                                         // enough! These points correspond 
                                         // to the first point of Time Mark.
tm_corr_peak_indx

figure;
plot(tm_corr_rslt);
xtitle('Метки времени соответствуют пикам с амплитудой 140', 'время [мс]','Амплитуда корреляционной ф-ции');
xgrid();
//Format plot:
a=get("current_axes");
a.labels_font_size=3; a.children.children.thickness=3;
t=a.title; t.foreground=9; t.font_size=3;
a1=a.x_label; a1.font_size=3;
a2=a.y_label; a2.font_size=3;

//Take one string of data (3 seconds):
nav_bits_samples = trkRslt_Q_P2_v3(tm_corr_peak_indx(1) - 60 : tm_corr_peak_indx(1) - 60 + (10*3000) -1)';
//Each bit lasts 5 ms, make each bit last only 1 sample:
ndata = matrix(nav_bits_samples, 5, (length(nav_bits_samples) / 5));
ndata = sum(ndata, 'r');
ndata = sign(ndata);

figure;
plot(ndata);
xtitle('Данные для декодирования', 'время [мс]','биты');
xgrid();
//Format plot:
a=get("current_axes");
a.labels_font_size=3; a.children.children.thickness=3;
t=a.title; t.foreground=9; t.font_size=3;
a1=a.x_label; a1.font_size=3;
a2=a.y_label; a2.font_size=3;

//trellis = poly2trellis(7, [133 171]);
//ndata_dec1 = vitdec(floor(([0 0 ndata]+1)/2), trellis, 5, 'trunc','hard');
//ndata_dec1(22:24)
