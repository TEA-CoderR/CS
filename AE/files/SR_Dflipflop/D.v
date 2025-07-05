module D(output q, output notq,
	 input clock, input d);

   wire        s, r;

   assign
     r = clock & (~d);
   assign
     s = clock & d;

   SR sr(q, notq, s, r);

endmodule
   
