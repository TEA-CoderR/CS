module registro(output [N-1:0] out, 
		input [N-1:0] in,
		input 	     we, input clock);

   parameter N = 32;
   
   // registro interno
   reg [N-1:0] 		     inreg;
   
   // inizializzazione a 0 
   initial
     begin
	inreg = 0;
     end
   
   // scrive quando il clock va alto sse write enable == 1
   always @(posedge clock)
     begin
	if(we == 1'b1)
	  begin
	     inreg = in;
	  end
     end
   
   // il valore dell'uscita è sempre il contenuto del registro
   assign
     out = inreg;

endmodule // registro
