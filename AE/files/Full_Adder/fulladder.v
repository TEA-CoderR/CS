primitive fa_somma(output s, input r, input x1, input x2);

   table
      0 0 0 : 0 ;
      0 0 1 : 1 ;
      0 1 0 : 1 ;
      0 1 1 : 0 ;
      1 0 0 : 1 ;
      1 0 1 : 0 ;
      1 1 0 : 0 ;
      1 1 1 : 1 ;
   endtable
   
endprimitive // fa_somma

primitive fa_riporto(output s, input r, input x1, input x2);

   table
      0 0 0 : 0 ;
      0 0 1 : 0 ;
      0 1 0 : 0 ;
      0 1 1 : 1 ;
      1 0 0 : 0 ;
      1 0 1 : 1 ;
      1 1 0 : 1 ;
      1 1 1 : 1 ;
   endtable
   
endprimitive // fa_riporto

module fulladder(output riporto, output somma,
		 input ripin, input x1, input x2);

   fa_riporto m1(riporto, ripin, x1, x2);
   fa_somma   m2(somma, ripin, x1, x2);
   
endmodule // fulladder


