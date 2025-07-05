module Dflipflop(output q, output notq,
		 input clock, input d);

   wire 	       n1;
   wire 	       dummy;
   
   wire 	       notclock;

   assign
     notclock = ~clock;
   
   D master(n1, dummy, notclock, d);
   D slave(q, notq, clock, n1);

endmodule
