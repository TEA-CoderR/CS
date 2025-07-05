module testDflipflop();

   reg clock, d;
   wire q, notq;

   Dflipflop dlatch(q, notq, clock, d);

   always
     begin
	#1 clock = ~clock;
     end

   initial
     begin
	$dumpfile("test.vcd");
	$dumpvars;

	clock = 0;

	d = 0;

        d = 1;
	#2 d = 0;

        #2 d = 1;
	
	#5 $finish;
	
     end
   
endmodule
