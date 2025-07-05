module rete(output [N-1:0] out,
	    input [N-1:0] x,
	    input [N-1:0] y, 
	    input 	  mux1, mux2, wea, web, aluctl,
	    input 	  clock);

   parameter N = 8;

   wire [N-1:0] 	  outA, outB, newA, newB;

   registro #(N) regA(outA, newA, 1'b1, clock);
   registro #(N) regB(outB, newB, 1'b1, clock);

   Sigma #(N) sigma(newA, newB, wea, web, mux1, mux2, aluctl, 
		    x, y, outA, outB);
   Omega #(N) omega(out, aluctl, outA, outB);

endmodule

