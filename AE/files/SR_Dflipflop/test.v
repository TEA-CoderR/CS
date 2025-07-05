module test();

   reg r,s;
   wire q, notq;

   SR sr(q,notq,s,r);

   initial
     begin
	$dumpfile("test.vcd");
	$dumpvars;

	r = 0;
	s = 0;

	#5
	  s = 1;

	#5
	  s = 0;
	r = 1;

	// adesso set e poi 0 0 
	#5
	  s = 1;
	r = 0;
	// si vede che il valore permane
	#5
	  s = 0;
	r = 0;

	// adesso reset e poi 0 0 
	#5
	  r = 1;

	#5
	  r = 0;

	// adesso tutti e due on (non dovrebbe succedere ma fa problemi)
	#5
	  s = 1;
	r = 1;
	

	#10 $finish;
     end
   
endmodule
