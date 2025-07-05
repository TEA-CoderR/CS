module testm();

   parameter M = 8;
   parameter N = 4;

   reg [M-1:0] Min;
   reg 	       wrt, clk;
   reg [N-1:0] addr1,addr2;
   wire [M-1:0]   Mout1, Mout2;
   
   banco #(M,N) MEM(Mout1, Mout2, Min, wrt, clk, addr1, addr2);

   always
     begin
	#1 clk = ~clk;
     end

   initial
     begin
	$dumpfile("testb.vcd");
	$dumpvars;

	clk = 0;
	wrt = 0;
	addr1 = 0;
	addr2 = 0;
	

	#1
	  wrt = 1;
	addr1 = 7;
	Min = 127;

	#2
	  wrt = 0;

	#2
	  wrt = 1;
	addr1 = 8;
	Min = 255;

	#2
	  wrt = 0;
	addr1 = 7;

	#2
	  addr2 = 8;

	#2
	  addr2 = 0;
	

	#10 $finish;

     end
   
endmodule // testm
