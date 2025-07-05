module testFA();

   reg rin, a, b;
   wire rip, som;

   fulladder adder(rip, som, rin, a, b);

   initial
     begin
	$dumpfile("testFA.vcd");
	$dumpvars;


	a   = 0;
	b   = 0;
	rin = 1;

	#2;
	a   = 1;
	b   = 0;
	rin = 1;

	#2;
	a   = 1;
	b   = 1;
	rin = 1;

	#2;
	a   = 1;
	b   = 1;
	rin = 0;


	
	#5 $finish;

     end
endmodule // testFA
