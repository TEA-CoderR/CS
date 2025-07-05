module testparity();


   reg clock;
   reg x;
   wire z;

   parity fsm(z,x,clock);

   initial
     begin
	clock = 0;
     end

   always
     begin
	#3 clock = 1;
	#1 clock = 0;
     end

   initial
     begin
	$dumpfile("test.vcd");
	$dumpvars;

	 x = 0;
	#3 x = 1;
	#4 x = 1;
	#4 x = 0;
	#4 x = 1;
	#4 x = 1;
	#4 x = 0;
	#4 x = 1;
	#4 x = 0;
	#4 x = 0;
	#4 x = 0;
	#4 x = 1;

	#10 $finish;
     end
   
endmodule // testparity
