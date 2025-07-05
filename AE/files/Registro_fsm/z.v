module z(output zeta, input [1:0]s, input [1:0]x);

   assign zeta = s[1]&s[0]&(~x[1])&x[0];
	     
endmodule // z

   
