module banco(output [M-1:0] memout1,
	     output [M-1:0] memout2,
	     input [M-1:0]  memin,
	     input 	    we,
	     input 	    clock,
	     input [N-1:0]  address1,
	     input [N-1:0]  address2,
   	     input [N-1:0]  address3);

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
	  m[address3] <= memin;
     end

   assign
     memout1 = m[address1];
   
   assign
     memout2 = m[address2];
   
endmodule // mem
