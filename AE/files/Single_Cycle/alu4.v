module alu4(output [N-1:0] o,
	   input   [N-1:0] a);
   
   parameter N = 32;
   assign
     o = a + 4;
    
endmodule // alu
