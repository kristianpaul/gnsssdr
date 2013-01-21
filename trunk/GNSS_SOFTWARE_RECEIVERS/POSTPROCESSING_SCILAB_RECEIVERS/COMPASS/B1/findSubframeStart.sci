function [firstString, activeChnList] = findSubframeStart(trkRslt_status, trkRslt_I_P, set_numberOfChnls)
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

  //--- Make a list of channels excluding not tracking channels --------------
  activeChnList = [];
  delFromActiveChnList = [];

  for k = 1:size(trkRslt_status, 1)
    if (trkRslt_status(k) ~= '-')
      activeChnList = [activeChnList k];
    end
  end

  //=== For all tracking channels ...
  for channelNr = activeChnList

    nav_bits = sign( trkRslt_I_P(channelNr, 1:$) ); //convert to +-1.

    //COMPASS B1 Preamble and secondary code. Bits order is reversed!
    preamble_bits = [-1 1 -1 -1 1 -1 -1 -1 1 1 1];
    secondary_code = [-1 1 1 1 -1 -1 1 -1 1 -1 1 1 -1 -1 1 -1 -1 -1 -1 -1];
    preamble_long = kron(preamble_bits, -secondary_code); //Preamble on sampling frequency 1000 Hz!
    preamble_corr_rslt = convol(preamble_long, nav_bits);//Convolution is used here 
                                             // instead of correlation. Just it 
                                             // was easier for me! In fact we 
                                             // calculate correlation because 
                                             // we use inverse-order Preamble in convolution.
    preamble_corr_rslt = preamble_corr_rslt(220:length(preamble_corr_rslt)); //First 220 points are of no interest!

    index = find( abs(preamble_corr_rslt) > 200)'; //Find places where 
                                             // correlation-result is high 
                                             // enough! These points correspond 
                                             // to the first point of Preamble.
    //pause;
    // If we have not found preamble - remove sat from the list:
    if isempty(index) then
      delFromActiveChnList = [delFromActiveChnList channelNr];
    else
      firstString(channelNr) = index(1);
    end
    
  end
  
  activeChnList(delFromActiveChnList) = [];
  
endfunction
