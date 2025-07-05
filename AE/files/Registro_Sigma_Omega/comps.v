module mux(output [N-1:0] z, 
	   input [N-1:0] in1, 
	   input [N-1:0] in2, 
	   input 	 ctl);

   parameter N = 32;
   
   assign
     z = (ctl ? in2 : in1);

endmodule // mux

module registro(output [N-1:0] z,
		input [N-1:0] x,
		input 	      we,
		input 	      clock);

   parameter N = 32;

   reg [N-1:0] 		      r;

   initial
     r = 0;

   always @(posedge clock)
     if(we)
       r <= x;

   assign
     z = r;
   
endmodule // registro

module alu(output [N-1:0] z,
	   input [N-1:0] a,
	   input [N-1:0] b,
	   input 	 ctl);

   parameter N = 32;

   assign
     z = (ctl ? (a-b) : (a+b));

endmodule // alu

module rete(output [N-1:0] out,
	    input [N-1:0] x,
	    input [N-1:0] y, 
	    input 	  mux1, mux2, wea, web, aluctl,
	    input 	  clock);

   parameter N = 32;

   wire [N-1:0] 	  mux2a, mux2b, a2alu, b2alu, alu2mux;

   mux #(N) m1(mux2a, x, alu2mux, mux1);
   mux #(N) m2(mux2b, y, alu2mux, mux2);
   registro #(N) rega(a2alu, mux2a, wea, clock);
   registro #(N) regb(b2alu, mux2b, web, clock);
   alu #(N) alu1(alu2mux, a2alu, b2alu, aluctl);

   assign
     out = alu2mux;
   
endmodule
   
   
