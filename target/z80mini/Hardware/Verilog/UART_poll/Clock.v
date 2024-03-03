module frequency_generator(
	input clock_in,
	output cpu_clk,
	output cpu_clk0,
	output t_clk,
	output con_clk,
	output con_clk0
);
	reg [5:0] con_counter = 6'd0;
	reg [2:0] cpu_counter = 3'd0;
	reg t = 1'd0;

	always @(posedge clock_in)
		begin
			con_counter <= con_counter + 1;
			cpu_counter <= cpu_counter + 1;
			if(con_counter >= 53) begin
				con_counter <= 0;
			end
			if(cpu_counter >= 4) begin
				cpu_counter <= 0;
				t <= ~ t;
			end
		end

	assign cpu_clk = cpu_counter[1]; // 10MHz
	assign cpu_clk0 = cpu_counter == 0;
	assign t_clk = t; // 5MHz
	assign con_clk = con_counter >= 27; // 925925/16=57870(0.47%)
	assign con_clk0 = con_counter == 0;

endmodule