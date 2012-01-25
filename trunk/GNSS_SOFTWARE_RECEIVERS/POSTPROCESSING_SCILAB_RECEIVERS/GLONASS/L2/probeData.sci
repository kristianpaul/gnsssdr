function probeData(settings)
//Function plots raw data information: time domain plot, a frequency domain
//plot and a histogram.
//
//The function can be called in two ways:
//   probeData(settings)
// or
//   probeData(fileName, settings)
//
//   Inputs:
//       fileName        - name of the data file. File name is read from
//                       settings if parameter fileName is not provided.
//
//       settings        - receiver settings. Type of data file, sampling
//                       frequency and the default filename are specified
//                       here.

//--------------------------------------------------------------------------
//                           SoftGNSS v3.0
//
// Copyright (C) Dennis M. Akos
// Written by Darius Plausinaitis and Dennis M. Akos
// Updated and converted to scilab 5.3.0 by Artyom Gavrilov
//--------------------------------------------------------------------------
//This program is free software; you can redistribute it and/or
//modify it under the terms of the GNU General Public License
//as published by the Free Software Foundation; either version 2
//of the License, or (at your option) any later version.
//
//This program is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.
//
//You should have received a copy of the GNU General Public License
//along with this program; if not, write to the Free Software
//Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
//USA.

// Generate plot of raw data ==============================================
[fid, message] = mopen(settings.fileName, 'rb');

if (fid > 0)
    // Move the starting point of processing. Can be used to start the
    // signal processing at any point in the data record (e.g. for long
    // records).
    mseek(settings.skipNumberOfBytes, fid);

    // Find number of samples per spreading code
    samplesPerCode = round(settings.samplingFreq / ...
                          (settings.codeFreqBasis / settings.codeLength));

    if (settings.fileType==1)
        dataAdaptCoeff=1;
    else
        dataAdaptCoeff=2;
    end

    // Read 100ms of signal
   data = mget(dataAdaptCoeff*100*samplesPerCode, settings.dataType, fid);
   count = length(data);

    mclose(fid);
    
    if (count < dataAdaptCoeff*100*samplesPerCode)
        // The file is to short
        error('Could not read enough data from the data file.');
    end

    //--- Initialization ---------------------------------------------------
    figure(100);
    clf(100);

    timeScale = 0 : 1/settings.samplingFreq : 5e-3;

    //--- Time domain plot -------------------------------------------------
    if (settings.fileType==1)

        subplot(2, 2, 3);
        plot(1000 * timeScale(1:round(samplesPerCode/50)), ...
             data(1:round(samplesPerCode/50)));
        xtitle('Time domain plot', 'Time (ms)', 'Amplitude');
    else

        data = data(1:2:$) - %i.*data(2:2:$);
        subplot(3, 2, 4);
        plot(1000 * timeScale(1:round(samplesPerCode/50)), ...
            real(data(1:round(samplesPerCode/50))));
        xtitle('Time domain plot (I)', 'Time (ms)', 'Amplitude');

        subplot(3, 2, 3);
        plot(1000 * timeScale(1:round(samplesPerCode/50)), ...
            imag(data(1:round(samplesPerCode/50))));
        xtitle('Time domain plot (Q)', 'Time (ms)', 'Amplitude');
    end

    //--- Frequency domain plot --------------------------------------------

    if (settings.fileType==1) //Real Data
        subplot(2,1,1);
         //Should be corrected in future! Some problems with amplitude?
        sm = 10*log10( pspect(settings.samplingFreq/1000 - 1000, ...
                      settings.samplingFreq/1000, 'hm', data) );
        plot(sm(1:length(sm)/2));
    else // I/Q Data
        subplot(3,1,1);
        sm = 10*log10( pspect(settings.samplingFreq/1000 - 1000, settings.samplingFreq/1000, 'hm', data) );
        plot(-length(sm)/2:1:length(sm)/2-1 ,[sm($/2+1:$) sm(1:$/2)]);
    end

    xtitle('Frequency domain plot', 'Frequency (kHz)', 'Magnitude');
    xgrid(0);

    //--- Histogram --------------------------------------------------------

    if (settings.fileType == 1)
        subplot(2, 2, 4);
        histplot(32, data, normalization=%f);
        xtitle('Histogram', 'Bin', 'Number in bin');
    else
        subplot(3, 2, 6);
        histplot(32, real(data), normalization=%f);
        xtitle('Histogram (I)', 'Bin', 'Number in bin');

        subplot(3, 2, 5);
        histplot(32, imag(data), normalization=%f);
        xtitle('Histogram (Q)', 'Bin', 'Number in bin');

    end
else
    //=== Error while opening the data file ================================
    error('Unable to read file!');
end // if (fid > 0)

endfunction
