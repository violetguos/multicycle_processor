`timescale 1 ps / 1 ps

module mux3to1my (
	data0x,
	data1x,
	data2x,
	sel,
	result);

	input	[7:0]  data0x;
	input	[7:0]  data1x;
	input	[7:0]  data2x;
	input	[2:0]  sel;
	output reg [7:0]  result;

	always @(*)
	begin
		case (sel)
			3'b000: result <= data0x;
			3'b001: result <= data1x;
			3'b010: result <= data2x;
			
			default: result <= 8'b0;
		endcase
	end
	
endmodule