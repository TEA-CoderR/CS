module sigma(output s1, input x, input s);

   assign
     s1 = (s & (~x)) | ((~s) & x);
   
   
endmodule
