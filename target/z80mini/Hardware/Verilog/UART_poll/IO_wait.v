module IO_wait(
   input wire clk, n_res, n_iorq,
	output wire n_wait
);

	reg [1:0] iowait;
   
	always @(posedge clk) begin
		if (!n_res) begin
			iowait <= 2'b00;
		end else begin
			iowait[0] <= n_iorq;
			iowait[1] <= iowait[0];
		end
	end
	
	assign n_wait = ~(~iowait[0] & iowait[1]);

endmodule