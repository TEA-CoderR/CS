module Omega(output [N-1:0] z,
	     input 	    aluctl,
	     input [N-1:0]  A,
	     input [N-1:0]  B);

   parameter N = 32;
   
   assign
     z = (aluctl == 0 ? A+B : A-B);
      
endmodule


