module parity(output z, input x, input clock);

   reg stato,nuovostato;

   initial
     stato = 0;

   always @(posedge clock)
     stato <= nuovostato;

   always @(x,stato)
     begin
	nuovostato <= (stato == 0 ? ( x == 0 ? 0 : 1) :
		      ( x == 0 ? 1 : 0));
     end

   assign
     z = (stato == 0 && x == 0) || (stato == 1 && x == 1);
	//     z = ((~stato)&(~x) | (stato&x));

   
endmodule
