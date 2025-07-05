module Sigma(output [N-1:0] newA,
	     output [N-1:0] newB,
	     input 	    wea, web, mux1, mux2, aluctl,
	     input [N-1:0]  X,
 	     input [N-1:0]  Y,
	     input [N-1:0]  A,
	     input [N-1:0]  B);

   parameter N = 32;
   
   assign
     newA = (wea == 0 ? A :
	     (mux1 == 0 ? X :
	      (aluctl == 0 ? A+B : A-B)));

   assign
     newB = (web == 0 ? B :
	     (mux2 == 0 ? Y :
	      (aluctl == 0 ? A+B : A-B)));
   
endmodule


