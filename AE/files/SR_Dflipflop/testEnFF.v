module testENff();

   reg clock, d, e;
   wire q, notq;

   EFlipFlop dlatch(q, notq, clock, d, e);

   always
     begin
	#1 clock = ~clock;
     end

   initial
     begin
	$dumpfile("test.vcd");
	$dumpvars;

	clock = 0;

        d = 1;
	e = 1;
	
	#2 d = 0;

        #2 d = 1;

	#2 e = 0;
	d = 1;

	#2 d = 0;
	
	#5 $finish;
	
     end
   
endmodule
