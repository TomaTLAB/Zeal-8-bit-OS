module signal_conditioner(
   input wire clk, clk0, sig_in,
	output reg sig_out
);

	always @(posedge clk) begin
		if (clk0) begin
			if (sig_in) begin
				sig_out <= 1;
			end else sig_out <= 0;
		end
	end

endmodule