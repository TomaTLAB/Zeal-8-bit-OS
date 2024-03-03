module IO_wait(
   input wire clk, clk0, n_res, n_iorq,
	output wire io_wt
);

	reg [1:0] iowait;
   
	always @(posedge clk) begin
		if (!n_res) begin
			iowait <= 2'b00;
		end else begin
			if (clk0) begin
				iowait[0] <= n_iorq;
				iowait[1] <= iowait[0];
			end
		end
	end
	
	assign io_wt = ~iowait[0] & iowait[1];

endmodule