function [firstPage, activeChnList] = findPageStart(trkRslt_status, trkRslt_I_P, set_numberOfChnls)
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

    //GALILEO E1 synchronisation pattern. Bits order is reversed!
    sync_pattern = [-1 -1 -1 -1 -1 1 1 -1 1 -1];
    sync_pattern_long = kron(sync_pattern, ones(1,4)); //Preamble on sampling frequency 1000 Hz!
    sync_pattern_corr_rslt = convol(sync_pattern_long, nav_bits);//Convolution is used here 
                                             // instead of correlation. Just it 
                                             // was easier for me! In fact we 
                                             // calculate correlation because 
                                             // we use inverse-order Preamble in convolution.
    sync_pattern_corr_rslt = sync_pattern_corr_rslt(40:length(sync_pattern_corr_rslt)); //First 40 points are of no interest!

    index = find( abs(sync_pattern_corr_rslt) > 38)'; //Find places where 
                                             // correlation-result is high 
                                             // enough! These points correspond 
                                             // to the first point of Preamble.
    sync_pattern_found = 0;
    for i = 1:length(index)
      index2 = index - index(i);
      if (~isempty(find(index2 == 1000))) then
        firstPage(channelNr) = index(i);
        sync_pattern_found = 1;
        break;
      end
    end
    
    // If we have not found preamble - remove sat from the list:
    if (sync_pattern_found == 0) then
      delFromActiveChnList = [delFromActiveChnList channelNr];
    end
    
  end
  
  activeChnList(delFromActiveChnList) = [];
  
endfunction
