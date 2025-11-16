`timescale 1ns/1ps

module register#(parameter WIDTH = 4) (
	output reg [WIDTH-1:0] reg_out,
	input [WIDTH-1:0] reg_in,
	input clk, rst
);

	always @ (posedge clk)
	if( !rst )
		reg_out <= 0;
	else
		reg_out <= reg_in;

endmodule
