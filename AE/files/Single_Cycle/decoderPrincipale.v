module decoderPrincipale(output Branch, 
			 output MemtoReg, 
			 output MemW, 
			 output ALUSrc, 
			 output [1:0]ImmSrc, 
			 output RegW, 
			 output [1:0]RegSrc, 
			 output ALUOp, 
			 input [1:0] OP, 
			 input Funct5, 
			 input Funct0);

   assign 
     Branch =   
		(OP == 2'b10 ? 1'b1 : 1'b0);

   assign 
     MemtoReg = 
		(OP == 2'b01 && Funct0 == 1 ? 1'b1 : 1'b0);

   assign
     MemW =     
		(OP == 2'b01 && Funct0 == 0 ? 1'b1 : 1'b0);

   assign
     ALUSrc =   
		(Funct5 == 0 ? 1'b0 : 1'b1);

   assign
     ImmSrc = 
	      (OP == 2'b00 ? 2'b00 :
	       (OP == 2'b01 ? 2'b01 : 2'b10));

   assign
     RegW   =
	     ((OP == 2'b00 || (OP == 2'b01 && Funct0 == 1)) ? 1'b1 : 1'b0);

   assign
     RegSrc =
	     ((OP == 2'b00 || (OP == 2'b01 && Funct0 == 1)) ? 2'b00 :
	      ((OP == 2'b01 && Funct0 == 0) ? 2'b00 : 2'b01));

   assign
     ALUOp =
	    (OP == 2'b00 ? 1'b1 : 1'b0);
   
       

endmodule

