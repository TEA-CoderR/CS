module rete1(output z, input x, input y);

   assign
     z = (~x) | (~y);

endmodule // rete1
