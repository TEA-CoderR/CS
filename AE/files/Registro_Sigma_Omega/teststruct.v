module test();

   parameter N = 8;

   reg [N-1:0] x, y;
   wire [N-1:0] out;
   reg 		mux1, mux2, wea, web, aluctl, clock;

   rete #(N) rr(out, x, y, mux1, mux2, wea, web, aluctl, clock);

   always
     #1 clock = ~clock;
   
   initial
     begin
	$dumpfile("test.vcd");
	$dumpvars;

	clock = 0;
	
	x = 8;
	y = 7;
	wea = 0;
	web = 0;
	aluctl = 0;
	mux1 = 0;
	mux2 = 0;


	#3 wea = 1;
 	#2 wea = 0;

	#2 web = 1;
	#2 web = 0;
	
	#2 mux2 = 1;
	web = 1;

	
	#10 $finish;
     end
endmodule
