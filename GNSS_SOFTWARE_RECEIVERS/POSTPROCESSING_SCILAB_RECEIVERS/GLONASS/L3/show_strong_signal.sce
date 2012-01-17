[fd01, err01] = mopen('e:\signal_I.bin', 'rb');
[fd02, err02] = mopen('e:\signal_Q.bin', 'rb');
[fd03, err03] = mopen('e:\carrier_I_svn11.bin', 'rb');
[fd04, err04] = mopen('e:\carrier_Q_svn11.bin', 'rb');
[fd05, err05] = mopen('e:\code_svn11.bin', 'rb');

len=16e3;
signal_I = mget(len, 'd', fd01);
signal_Q = mget(len, 'd', fd02);
carrier_I = mget(len, 'd', fd03);
carrier_Q = mget(len, 'd', fd04);
code = mget(len, 'd', fd05);

plot(signal_I, 'r');
plot(2*carrier_I, 'b');
plot(2*code, 'g');

mclose(fd01);
mclose(fd02);
mclose(fd03);
mclose(fd04);
mclose(fd05);