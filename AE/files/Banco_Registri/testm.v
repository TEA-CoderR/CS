module testm();

   parameter M = 8;
   parameter N = 4;

   reg [M-1:0] Min;
   reg 	       wrt, clk;
   reg [N-1:0] addr;
   wire [M-1:0]   Mout;
   
   mem #(M,N) MEM(Mout, Min, wrt, clk, addr);

   always
     begin
	#1 clk = ~clk;
     end

   initial
     begin
	$dumpfile("testm.vcd");
	$dumpvars;

	clk = 0;
	wrt = 0;
	

	#1
	  wrt = 1;
	addr = 7;
	Min = 127;

	#2
	  wrt = 0;

	#2
	  wrt = 1;
	addr = 8;
	Min = 255;

	#2
	  wrt = 0;
	addr = 7;

	#2
	  addr = 8;

	#2
	  addr = 0;
	

	#10 $finish;

     end
   
endmodule // testm
