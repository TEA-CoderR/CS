module parity(output z, input x, input clock);

   wire outs, ins;
   
   registro #(1) r(outs, clock, 1'b1, ins);
   omega         o(z, x, outs);
   sigma         s(ins, x, outs);

endmodule // parity

