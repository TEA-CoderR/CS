module mem(output [M-1:0] memout,
	   input [M-1:0] memin,
	   input 	    we,
	   input 	    clock,
	   input [N-1:0]    address);

   parameter M=32;
   parameter N=10;

   reg [M-1:0] 		    m [0:2**N-1];
   integer 		    i;

   initial
     begin
	for(i=0; i<2**N-1; i++)
	  m[i] = 0;
     end

   always @(posedge clock)
     begin
	if(we)
	  m[address] <= memin;
     end

   assign
     memout = m[address];
   
endmodule // mem
