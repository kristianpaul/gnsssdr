function [firstString, activeChnList] = findTimeMarks(trkRslt_status, trkRslt_I_P, set_numberOfChnls)
///function [firstString, activeChnList] = findTimeMarks(trackResults, settings)
// findTimeMarks finds the first TimeMark occurrence in the bit stream of
// each channel. The TimeMark is a unique bit sequence!
// At the same time function returns list of channels, that are in
// tracking state.
//
//[firstSubFrame, activeChnList] = findTimeMarks(trackResults, settings)
//
//   Inputs:
//       trkRslt_status    - output from the tracking function (trackResults.status)
//       trkRslt_I_P       - output from the tracking function (trackResults.I_P)
//       set_numberOfChnls - Receiver settings (settings.numberOfChannels).
//
//   Outputs:
//       firstString     - the array contains positions of the first
//                       time mark in each channel. The position is ms count 
//                       since start of tracking. Corresponding value will
//                       be set to 0 if no valid preambles were detected in
//                       the channel.
//       activeChnList   - list of channels containing valid time marks
//--------------------------------------------------------------------------
// Written by Artyom Gavrilov
//--------------------------------------------------------------------------

// Preamble search can be delayed to a later point in the tracking results
// to avoid noise due to tracking loop transients 
searchStartOffset = 0;

//--- Initialize the firstSubFrame array -----------------------------------
firstSubFrame = zeros(1, set_numberOfChnls);

//--- Make a list of channels excluding not tracking channels --------------
activeChnList = 0;

for k = 1:size(trkRslt_status, 1)
    if (trkRslt_status(k) ~= '-')
        activeChnList = [activeChnList k];
    end
end
if length(activeChnList) == 1
    clear activeChnList;
else
    activeChnList = activeChnList(2:$);
end

//=== For all tracking channels ...
for channelNr = activeChnList

  nav_bits = sign( trkRslt_I_P(channelNr, 1 + searchStartOffset : $) ); //convert to +-1.
  
  //GLONASS Time Mark. bits order is reversed!
  tm_bits = [-1 1 1 -1 1 -1 -1 1 -1 -1 -1 -1 1 -1 1 -1 1 1 1 -1 1 1 -1 -1 -1 1 1 1 1 1]; 
  tm_long = kron(-tm_bits, ones(1,10)); //Time Mark on sampling frequency 1000 Hz!
  tm_corr_rslt = convol(tm_long, nav_bits);//Convolution is used here 
                                           // instead of correlation. Just it 
                                           // was easier for me! In fact we 
                                           // calculate correlation because 
                                           // we use inverse-order Time Mark in convolution.
  tm_corr_rslt = tm_corr_rslt(300:length(tm_corr_rslt)); //First 300 points are of no interest!
  
  index = find( abs(tm_corr_rslt) > 290)'; //Find places where 
                                           // correlation-result is high 
                                           // enough! These points correspond 
                                           // to the first point of Time Mark.
  firstString(channelNr) = index(1);
end

endfunction
