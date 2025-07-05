module test();

   // ingressi
   reg [1:0] x;
   // clock;
   reg 	     clock;
   // uscita
   wire      z;


   // modulo sotto test
   fsm_me mealy(z, x, clock);

   // generazione del segnale di clock
   always
     begin
	#1 clock = ~clock;
     end

   // main
   initial
     begin
	$dumpfile("test.vcd");
	$dumpvars;

	clock = 0;
	x = 0;  // x = A

	// x = B
	#3 x = 1;
	// x = C;
	// #2 x = 3;
	#2 x = 2'b11;
	// x = A
	#2 x = 0;
	#2 x = 1;
	#2 x = 1;
	

	// sequenza a a a b b c a b b 
	#2 x = 0;
	#2 x = 0;
	#2 x = 0;
	#2 x = 1;
	#2 x = 1;
	#2 x = 3;
	#2 x = 0;
	#2 x = 1;
	#2 x = 1;
	
	#10 $finish;
     end
endmodule // test

   

     
