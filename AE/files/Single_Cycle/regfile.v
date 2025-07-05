module regfile(output [31:0] RD1, // first reg out
	       output [31:0] RD2, // second reg out
	       output [31:0] RD3, // third reg out
	       input [31:0]  WD3, // value to store
	       input [31:0]  R15, // pc in value
	       input [3:0]   A1, // first read address
	       input [3:0]   A2, // second read address
	       input [3:0]   A3, // third read/write address
	       input 	     WE3, // write enable
	       input 	     CLK) ; // the clock

   reg [31:0] 		     rf[14:0];

   initial
     begin
	rf[0] = 32'd1;
	rf[1] = 32'd2;
	rf[2] = 32'd3;
	rf[3] = 32'd4;
	rf[4] = 32'd5;
	rf[5] = 32'd6;
	rf[6] = 32'd7;
	rf[7] = 32'd8;
	rf[8] = 32'd9;
	rf[9] = 32'd10;
     end
	
   always @(posedge CLK)
     begin
	if(WE3 == 1'b1)
	  begin
	     rf[A3] <= WD3;
	  end
     end

   assign
     RD1 = (A1 == 4'b1111 ? R15 : rf[A1]); //rf[A1]; // (A1 == 4'b1111 ? R15 : rf[A1]);
   assign
     RD2 = rf[A2]; // non si può leggere r15 qui
   assign
     RD3 = rf[A3];

endmodule

