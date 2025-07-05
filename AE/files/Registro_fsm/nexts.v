module nexts(output [1:0]s1,  input [1:0]s, input [1:0]x);

   assign
     s1[1] = (~s[1]) & s[0] & (~x[1]) & x[0];

   assign
     s1[0] = ((~x[1])&(~x[0])) | ((~s[1]) & s[0] & (~x[1]));
    
	     
endmodule // z

   
