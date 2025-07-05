module omega(output z, input x, input s);

  
   assign
     z = ( (~s)&(~x) ) | ( s & x) ;
   
   
endmodule
