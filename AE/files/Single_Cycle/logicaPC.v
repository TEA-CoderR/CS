module logicaPC(output PCS,
		input [3:0] Rd,
		input 	    RegW,
		input 	    Branch);

   assign
     PCS = ((Rd == 15) && RegW) || Branch;
    
endmodule // logicaPC

		
