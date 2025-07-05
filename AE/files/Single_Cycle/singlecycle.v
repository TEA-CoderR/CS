module singlecycle();

   // segnali da DataPath a parte controllo
   wire [31:0] Instr;
   
   wire [3:0] Cond;
   wire [1:0] Op;
   wire [5:0] Funct;
   wire [3:0] Rd;
   wire [3:0] Flags;

   // segnali da ParteControllo a DataPath
   wire       PCSrc, MemtoReg, MemWrite;
   wire [1:0] ALUControl;
   wire       ALUSrc;
   wire [1:0] ImmSrc;
   wire       RegWrite;
   wire [1:0] RegSrc;
   

   reg 	      CLK;
   
   
   DataPath dp(Instr, 
	       Flags[0], Flags[1], Flags[2], Flags[3],
	       PCSrc, RegSrc, RegWrite, ImmSrc, ALUSrc, ALUControl,
	       MemWrite, MemtoReg, CLK);
   parteControllo pc(
		     //output 
		     PCSrc, RegWrite, MemWrite, MemtoReg, ALUSrc,
		     ImmSrc, RegSrc, ALUControl,
		     // input
		     Instr[31:28], // cond
		     Flags,
		     Instr[27:26], // OP
		     Instr[25:20], // Funct
		     Instr[15:12], // Rd
		     CLK);

   always
     begin
	#1 CLK = ~CLK;
     end

   initial
     begin
	$dumpfile("testSC.vcd");
	$dumpvars;

	CLK = 0;
	
	#12
	  $finish;
     end

endmodule
