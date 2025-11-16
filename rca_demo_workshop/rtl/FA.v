`timescale 1ns/1ps

module FA(
	output S, Cout,
	input  A, B, Cin
);

	assign S    = A ^ B ^ Cin;
	assign Cout = A&B | (A|B)&Cin;

endmodule
