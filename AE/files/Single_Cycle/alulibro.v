// alu della figura 5.17
module somma(output carry, output [N-1:0] out, 
	     input [N-1:0] a, input [N-1:0] b, 
	     input 	   rip);
   
   parameter N = 32;
   wire [N:0] 		   full;
    
   assign
     {carry, out} = a + b + rip;

endmodule // somma

module not32(output [N-1:0] out, input [N-1:0] in);
   parameter N = 32;

   assign out = ~in;
endmodule // not32

module and32(output [N-1:0] out, input [N-1:0] a, input [N-1:0] b);
   parameter N = 32;

   assign out = a & b;
endmodule // not32

module or32(output [N-1:0] out, input [N-1:0] a, input [N-1:0] b);
   parameter N = 32;

   assign out = a | b;
endmodule // not32

module mux4x32(output [N-1:0] out, 
	       input [N-1:0] a, input [N-1:0] b, 
	       input [N-1:0] c, input [N-1:0] d, 
	       input [1:0]   ctl);

   parameter N = 32;
   
   assign
     out = (ctl[1] == 1'b0 ?
	    (ctl[0] == 1'b0 ? a : b) :
	    (ctl[0] == 1'b0 ? c : d));
endmodule // mux4x32

module mux2x32(output [N-1:0] out, 
	       input [N-1:0] a, input [N-1:0] b, 
	       input 	     ctl);

   parameter N = 32;
   
   assign
     out = (ctl == 1'b0 ? a : b);
endmodule // mux4x32

module alu(output [N-1:0] Risultato,
	   output 	 Negative, Zero, Carry, oVerflow,
	   input [N-1:0] A,
	   input [N-1:0] B,
	   input [1:0] ControlloALU);

   parameter N = 32;
   
   wire [N-1:0] 	 not2mux;
   wire [N-1:0] 	 OpB;
   wire [N-1:0] 	 Somma;
   wire [N-1:0] 	 Or2Mux4;
   wire [N-1:0] 	 And2Mux4;
   wire [N-1:0]		 Risultato;

   // logica per la somma e sottrazione
   not32 #(N) not1(not2mux,B);                              // not B
   mux2x32 #(N) mux21(OpB,B,not2mux,ControlloALU[0]);       // scelta fra B e not B
   somma #(N) alu1(Rout, Somma, A, OpB, ControlloALU[0]);   // somma (sottrazione)

   // logica per or e and
   or32 #(N) or1(Or2Mux4, A, B);                            
   and32 #(N) and1(And2Mux4, A, B);

   // scelta del risultato fra i 3 possibili (replicata somma anche sull'ultimo input)
   mux4x32 #(N) mux41(Risultato,  Somma, Somma, And2Mux4, Or2Mux4, ControlloALU);

   // logica per i flag
   // Zero
   wire [N-1:0] 	 w1;
   not32 #(N) n2(w1,Risultato);
   assign Zero = &w1;
   // Negative
   assign
     Negative = Risultato[N-1];
   // Carry
   assign Carry = (~ControlloALU[1] & Rout);
   // overflow
   assign oVerflow = (~(ControlloALU[0] ^ A[N-1] ^ B[N-1])) &
	      (A[N-1] ^  Somma[N-1]) &
	      (~ControlloALU[1]);
endmodule // alu

