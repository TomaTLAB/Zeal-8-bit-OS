module frequency_generator(
    input clock_in,
    output cpu_clk,
    output t_clk,
    output con_clk,
    output tim_clk
	 
);
    reg [3:0] pre_counter = 4'd0;
	 reg [3:0] main_counter = 3'd0;

    always @(posedge clock_in)
        begin
            pre_counter <= pre_counter + 4'd1;
            if(pre_counter >= 4) begin
					pre_counter <= 4'd0;
					main_counter <= main_counter + 3'd1; // Increment at 10MHz
				end
        end
		  
    assign t_clk = main_counter[0]; // 5MHz
    assign cpu_clk = main_counter[0]; // 5 MHz
    assign con_clk = main_counter[3]; // 625 KHz
    assign tim_clk = ~|main_counter; // 625 KHz

endmodule