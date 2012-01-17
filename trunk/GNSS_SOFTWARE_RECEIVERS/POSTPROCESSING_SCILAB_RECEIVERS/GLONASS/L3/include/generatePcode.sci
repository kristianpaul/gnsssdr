function Pcode = generatePcode(PRN)
// generatePcode.m generates GLONASS P-code.
//
// Pcode = generatePcode(PRN)
//
//   Inputs:
//       PRN         - PRN number of the sequence.
//
//   Outputs:
//       Pcode      - a vector containing the desired P code sequence 
//                   (chips).  
//------------------------------------------------------------------------------

if PRN == 101  then //PRN=101 - GLONASS PRN code generation.
  reg = -1*ones(1,25);
  for i=1:5110000
    g3(i)=reg(25);
    msave=reg(3)*reg(25);
    reg(2:25)=reg(1:24);
    reg(1)=msave;
  end;
  Pcode=-g3'; 
end

endfunction
