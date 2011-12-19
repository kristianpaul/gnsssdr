function decoded_data = decode_gl_data(data)
// decode_gl_data used to decode data. Data is coded by differential coding
// technique. This function make differential decoding. It additionaly makes
// conversion from 1000 bits per second to 50 bits per second.
//
//decoded_data = decode_gl_data(data)
//
//   Inputs:
//       data            - output from the tracking function
//
//   Outputs:
//       decoded_data    - decoded string (85 data bits)
//--------------------------------------------------------------------------
// Written by Artyom Gavrilov
//--------------------------------------------------------------------------

  ndata = data(1:1700);

  meandr = ones(1, 170);
  meandr(2:2:$) = -1;
  meandr = kron(-meandr, ones(1,10));// Auxiliary meandr that should be 
                                     //removed from the data.

  ndata = ndata .* meandr; //Remove meandr from data.

  //Convert 20 bits to 1 bit.
  ndata = matrix(ndata, 20, (length(ndata) / 20));
  ndata = sum(ndata, 'r');
  ndata = sign(ndata);

  for j=1:84
    decoded_data(1,(85-j)) = -ndata(j)*ndata(j+1);
  end
  decoded_data(85) = -1; //first symbol is always empty symbol. 
  
endfunction 