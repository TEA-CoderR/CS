module decoder(output PCS, RegW, MemW, MemtoReg, ALUSrc,
	       output [1:0] ImmSrc,
	       output [1:0] RegSrc,
	       output [1:0] ALUControl,
	       output [1:0] FlagW,

	       input [3:0] Rd, 
	       input [1:0] OP, 
	       input [5:0] Funct);

   wire 		   Branch;
   wire 		   ALUOp;
		   

   decoderALU decAlu(ALUControl, FlagW, ALUOp, Funct[4:0]);
   decoderPrincipale decPrinc(Branch, MemtoReg, MemW, ALUSrc,
			      ImmSrc, RegW, RegSrc, ALUOp,
			      OP, Funct[5], Funct[0]);
   logicaPC logPC(PCS, Rd, RegW, Branch);

endmodule // decoder
