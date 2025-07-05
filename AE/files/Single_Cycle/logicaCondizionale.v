module logicaCondizionale(output PCSrc, RegWrite, MemWrite,
			  input       PCS, RegW, MemW, 
			  input [1:0] FlagW,
			  input [3:0] Cond,
			  input [3:0] ALUFlags, 
			  input CLK);

   reg [3:0] FLAGS;
   wire      CondEx;
   
   controlloCondizioni contrCond(CondEx, Cond, 
				 ALUFlags[0], ALUFlags[1], ALUFlags[2], ALUFlags[3]);

   // scrittura nel flag (in basso a sn in Fig. 7.14)
   always @(posedge CLK)
     begin
	if(FlagW[1] && CondEx)
	  FLAGS[3:2] = ALUFlags[3:2];
	if(FlagW[0] && CondEx)
	  FLAGS[1:0] = ALUFlags[1:0];
     end

   assign
     PCSrc = PCS && CondEx;
   assign
     RegWrite = RegW && CondEx;
   assign
     MemWrite = MemW && CondEx;
   
endmodule // logicaCondizionale

		       
