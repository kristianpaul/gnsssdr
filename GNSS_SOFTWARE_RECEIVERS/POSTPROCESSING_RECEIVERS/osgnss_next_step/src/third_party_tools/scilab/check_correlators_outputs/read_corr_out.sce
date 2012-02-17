  clear all;
  clc;

  fileName='e:\corr_out.csv';
  [fd, err] = mopen(fileName, 'rt');
  
  s =  mgetl(fd);
  
  [Ie s] = strtod(s);
  [Qe s] = strtod(s);
  [Ip s] = strtod(s);
  [Qp s] = strtod(s);
  [Il s] = strtod(s);
  [Ql s] = strtod(s);
  [cross s]   = strtod(s);
  [dot s]     = strtod(s);
  [freqErr s] = strtod(s);
  [carrErr s] = strtod(s);
  [codeErr s] = strtod(s);
  
  carrFreq = strtod(s);
  
  mclose(fd);
  
  plot(Ie, 'r');
  plot(Qe, 'b');
  plot(Ip, 'g');
  plot(Qp, 'c');
  plot(Il, 'y');
  plot(Ql, 'm');
  
//  figure;
//  plot(dot, 'r');
//  plot(cross, 'b');
//  
//  figure;
//  plot(freqErr, 'b');
//  
//  figure;
//  plot(carrErr, 'b');
//  
//  figure;
//  plot(codeErr, 'b');s
//  
//  figure;
//  plot(freqErr, 'r');
//  plot(dot, 'g');
//  plot(cross, 'b');