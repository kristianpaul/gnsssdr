clear;
clc;
//Reading data from text file:
N = read_csv('i_carr.dat');
N = evstr(N);//Problems happen when converting n
             //on-numbers! (For example 'x' value).

//Replace 0 by -1;
f0 = find(N==0);
N(f0) = -1;
//Replace 1 by -2;
f1 = find(N==1);
N(f1) = -2;
//Replace 2 by +1;
f2 = find(N==2);
N(f2) = +1;
//Replace 3 by 2;
f3 = find(N==3);
N(f3) = +2;

//Plot spectrum.
plot(abs(fft(N(1:5000))))
