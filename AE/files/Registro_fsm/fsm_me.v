module fsm_me(output y, input [1:0]x, input clock);

   // wire necessari a connettere i componenti
   // uscita della rete combinatoria che calcola il nuovo stato
   wire [1:0] ns2s;
   // uscita del registro di stato 
   wire [1:0] s2ns;

   // il registro di stato (enable sempre a 1: ogni ciclo di clock scrive)
   registro #(2) stato(s2ns,ns2s,1'b1,clock);

   // rete combinatoria che calcola il valore del prossimo stato a partire
   // dallo stato corrente e dagli ingressi (RETE DI MEALY)
   nexts prossimostato(ns2s,s2ns,x);
   // rete combinatoria che calcola l'uscita a partire
   // dallo stato corrente e dagli ingressi (RETE DI MEALY)
   z zeta(y, s2ns, x);
   
endmodule

