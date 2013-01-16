function decoded_data = decode_gll_data(data)
// decode_gll_data used to decode data. It additionaly makes
// conversion from 1000 bits per second to 250 bits per second.
//
//decoded_data = decode_gll_data(data)
//
//   Inputs:
//       data            - output from the tracking function
//
//   Outputs:
//       decoded_data    - decoded halfpage
//--------------------------------------------------------------------------
// Written by Artyom Gavrilov
//--------------------------------------------------------------------------

  ndata = data(1:1000);

  sync_pattern = [-1 1 -1 1 1 -1 -1 -1 -1 -1];

  //Convert 4 bits to 1 bit.
  ndata = matrix(ndata, 4, (length(ndata) / 4));
  ndata = sum(ndata, 'r');
  ndata = sign(ndata);

  if (sign(sum(ndata(1:10).*sync_pattern))==-1) then
    ndata = -ndata;
  end

  //deinterleave data:
  ndata=matrix(ndata(11:$), 30, 8);//Is this correct???
  ndata = ndata';
  ndata=matrix(ndata, 1, length(ndata));
  
  //convolutional decoding:
  n = 2;                             //coder rate;
  m = 7;                             //coder constraint length;
  x = [1 0 1 1 0 1 1;1 1 1 1 0 0 1]; //coder polynomial;
  
  decoded_data = convol_decoder(floor((ndata+1)/2), n, m, x);
  
endfunction 
