`timescale 1ns/1ps
`define clock_period 5

module rca_tb();

	localparam WIDTH = 4;

	reg [WIDTH-1:0] a, b;
	reg cin, clk, rst;
	wire [WIDTH:0] sum;

	// DUT instantiation
	RCA DUT (.clk(clk), .rst(rst), .a(a), .b(b), .cin(cin), .sum(sum));

	// Clock generation
	always #(`clock_period/2) clk = ~clk;

	// Driving stimulus
	initial
	begin
		clk = 1'b0;
		rst = 1'b0;

		a = 4'b0000;
		b = 4'b0001;
		cin = 1'b0;

		#20
		rst = 1'b1;

		#10
		a = 4'b0111;
		b = 4'b0001;
		cin = 1'b0;
		
		#10
		a = 4'b0001;
		b = 4'b0101;
		cin = 1'b0;
		
		#10
		a = 4'b0010;
		b = 4'b0101;
		cin = 1'b0;
		
		#30
		$finish();

	end

    initial
    begin
       $sdf_annotate("../DC/results/RCA.mapped.sdf",rca_tb.DUT,,,"MAXIMUM");
    end

   

endmodule
