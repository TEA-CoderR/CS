module testRete1();

   // un registro per ognuno degli ingressi del modulo sotto test
   reg a,b;

   // un filo per ognuna delle uscite del modulo sotto test
   wire c;

   // istanziare il modulo sotto test (nome del modulo nel .v => tipo)
   rete1 myRete1(c,a,b);

   // qui si dice come si comporta il "main" ...
   initial
     begin
	// vogliamo vedere i cambiamenti delle variabili sul file test.vcd
	$dumpfile("test.vcd");
	// vogliamo vedere tutte le variabili
	$dumpvars;


	// inizialmente a e b sono a 0 (prima riga della tabella di verita')
	a = 0;
	b = 0;

	// dopo un po' (3 unità di tempo)
	#3
 	  // b diventa 1 (seconda riga della TV)
	  b = 1;

	// dopo un altro po' a diventa 1 e b diventa 0
	#3
	  b = 0;
	a = 1;

	// infine tutti e due a 1
	#3
	  b = 1;

	// aspettiamo un po'
	#5
	  // e finiamo il test
	  $finish;


     end // initial begin
endmodule // testRete1

	  
	 
