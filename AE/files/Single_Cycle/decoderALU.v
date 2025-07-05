module decoderALU(output  [1:0] ALUControl,
		  output [1:0] FlagW,
		  input        ALUOp,
		  input [4:0]  Funct);

   assign
     ALUControl = 
		  (ALUOp == 0 ? 2'b00 :
		   (Funct[4:1] == 4'b0100 ? 2'b00 : 
		    (Funct[4:1] == 4'b0010 ? 2'b01 :
		     (Funct[4:1] == 4'b0000 ? 2'b10 : 2'b11))));
   assign
     FlagW =
	    (ALUOp == 1'b0 ? 2'b00 :
	     (Funct[0] == 1 ? ((Funct[4:1] == 4'b0100 || Funct[4:1] == 4'b0010) ? 2'b11 : 2'b10) : 2'b10)
	     );

   
endmodule // decoderALU
