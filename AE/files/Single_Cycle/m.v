module m(output [N-1:0] out,
	 input [N-1:0] in,
	 input [M-1:0] addr,
	 input 	       we,
	 input 	       clock);

   parameter N = 32;
   parameter M = 10;
   
   integer 	      i;

   reg [N-1:0] 	      mem[2**M-1:0];

   initial
     begin
	for(i=0;i<1024;i=i+4)
	  mem[i] = i/4;
     end
   
   always @(posedge clock)
     begin
	if(we == 1)
	  begin
	     mem[addr] <= in;
	  end
     end

   assign
     out = mem[addr];
   
endmodule
