module extend(output [31:0] o,
	      input [N-1:0] i,
	      input [1:0] ExtImm);
   

   parameter N = 24;
   
   // notazione e codice della Tabella 7.1
   assign 
     //                     immediato senza segno a 8 bit
      o = (ExtImm == 2'b00 ? {24'd0,i[7:0]} :
	      
	      //                 immediato senza segno 12 bit
	      (ExtImm == 2'b01 ? {20'd0,i[11:0]} :
	       
	       //             immediato da 24 bit (signed)
	       (i[N-1] == 1 ? {6'b111111,i[N-1:0],2'b00} : {6'b000000,i[N-1:0],2'b00})
	       )
	      );
   
   
     
endmodule // extend
