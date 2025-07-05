module registro(output [N-1:0]z, input [N-1:0]x, input en, input clk);

   // si può definire la lunghezza del registro come parametro del modulo
   parameter N = 8;

   // questo è il dispositivo fisico che contiene lo stato
   reg [N-1:0] s;

   // inizializzazione (visto che non abbiamo il reset)
   initial
     s = 0;
   
   // funzione di transizione dello stato interno:
   // quando il clock va alto, in presenza di enable
   // memorizza il valore che trovi in ingresso
   always @(posedge clk)
     begin
	if(en==1)
	  s = x;
     end

   // il valore dell'uscita è sempre il valore del registro
   assign z = s;

endmodule // reg
