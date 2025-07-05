module EFlipFlop(output q, output notq,
		 input clock, input d, input en);

   wire 	       c1;

   assign
     c1 = clock & en;

   Dflipflop ff(q, notq, c1, d);

endmodule
