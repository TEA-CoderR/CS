module parteControllo(output PCSrc, RegWrite, MemWrite, MemtoReg, ALUSrc,
		      output [1:0] ImmSrc,
		      output [1:0] RegSrc,
		      output [1:0] ALUControl,

		      input [3:0]  Cond,
		      input [3:0]  ALUFlags,

		      input [1:0]  Op,
		      input [5:0]  Funct,
		      input [3:0]  Rd, 
		      input CLK);

   wire [1:0] 			   FlagW;
   wire 			   PCS, RegW, MemW;
   

   logicaCondizionale lc(PCSrc, RegWrite, MemWrite,
			 PCS, RegW, MemW,
			 FlagW, Cond, ALUFlags,
			 CLK);
   decoder dec(PCS, RegW, MemW, MemtoReg, ALUSrc,
	       ImmSrc, RegSrc, ALUControl, FlagW,
	       Rd, Op, Funct);
   
endmodule // parteControllo
