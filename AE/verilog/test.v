module test();
	
	reg a,b;
	wire c;

	rete myRete(c,a,b);

	initial
		begin
			$dumpfile("test.vcd");
			$dumpvars;

			a = 0;
			b = 0;

			#2
				b = 1;

			#3
				a = 1;

			#2
				a = 0;
				b = 0;

			$finish;
		end
endmodule