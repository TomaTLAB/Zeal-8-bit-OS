module z80mini(
	input wire CLK50MHz,
	input wire [15:0] A,
	inout wire [7:0] D,
	input wire nMREQ, nIORQ, nWR, nRD, nM1, nRES, nHALT, CONIRQ,
	output wire nWAIT, nINT, nNMI, CPUCLK, nRESET,
	output wire CONCLK, TCLK, RESET, nCONCS,
	output wire nRAMCS, nROMCS,
	output wire [5:0] EXT_A,
	input wire RS, RW, E,
	input wire [3:0] EXT_P_IN,
	input wire [3:0] EXT_P_OUT
);

	reg res;
//	reg [7:0] do;
	wire [7:0] do;
	wire [7:0] int_vec;
	
	wire map_cs;
	wire ext_cs;
	wire ps2_cs;
	wire oe;
	
	reg [5:0] mapper [0:3];
//	reg [7:0] extport;
	wire [7:0] PS2_data_out;
	wire PS2_tim;
	wire PS2_irq;
	reg PS2_int;

//	frequency_divider #(.DIVIDER(10)) f_cpuclk (.clock_in(CLK50MHz), .clock_out(CPUCLK)); // CPUCLK = TCLK = 5Mhz
//	frequency_divider #(.DIVIDER(81)) f_conclk (.clock_in(CLK50MHz), .clock_out(CONCLK)); // CONCLK = 617 kHz = 9600
//	frequency_divider #(.DIVIDER(41)) f_conclk (.clock_in(CLK50MHz), .clock_out(CONCLK)); // CONCLK = 1219.5kHz = 19055 baud
//	assign TCLK = CPUCLK;

	frequency_generator fg0 (
		.clock_in(CLK50MHz),
		.t_clk(TCLK), .con_clk(CONCLK), .cpu_clk(CPUCLK), .tim_clk(PS2_tim)
	);

	IO_wait iow0 (
	   .clk(CPUCLK), .n_res(nRESET), .n_iorq(nIORQ), 
		.n_wait(nWAIT) 
	);

	
	PS2_receiver ps2r(
		.clk(CPUCLK), .n_res(nRESET), .ps2_clock(RS), .ps2_data(RW), .tim_clk(PS2_tim),
		.ps2_done(PS2_irq), .ps2_out(PS2_data_out)
	);
		
		
	//Conditioning Reset signal
	always @(posedge CPUCLK) begin
		if (!nRES) begin
			res <= 1;
		end else res <= 0;
	end

	assign ps2_cs = (A[7:0] == 8'hE8); 
	assign ext_cs = (A[7:0] == 8'hD1);
	assign map_cs = (A[7:4] == 4'hF); // [0xF0..F3]...[0xFC..FF]

	assign oe = ~(nRD | nIORQ) & (ps2_cs | ext_cs | map_cs);

   always @(posedge CPUCLK) begin
		if (res) begin
			PS2_int <= 1'b0;
//			extport[7:0] <= 8'hFF;
			mapper[0][5:0] <= 6'h00;//0x000000
			mapper[1][5:0] <= 6'h20;//0x080000
			mapper[2][5:0] <= 6'h21;//0x084000
			mapper[3][5:0] <= 6'h22;//0x088000
		end else begin
			if (nIORQ == 0 && nWR == 0) begin
//				if (ext_cs) extport[7:0] <= D[7:0];
				if (map_cs) mapper[A[1:0]][5:0] <= D[5:0];
			end
			if (nIORQ == 0 && nRD == 0 && ps2_cs) begin
				PS2_int <= 1'b0;
			end else begin
				if (PS2_irq) begin
					PS2_int <= 1'b1;
				end
			end
		end
	end

//	assign EXT_P_OUT[3:0] = extport[3:0];
	
	assign do[7:0] = ps2_cs ? PS2_data_out[7:0] : ext_cs ? {~PS2_int, 7'b1111111} : map_cs ? {2'b00, mapper[A[15:14]][5:0]} : 8'hFF;
	
	assign EXT_A[5:0] = mapper[A[15:14]][5:0];
	
	assign int_vec[7:0] = 8'h02; // Set INT vector to 0xIIFA (for CP/M: II = 0xFF)

	assign D[7:0] = nM1 | nIORQ ? (oe ? do[7:0] : 8'bzzzzzzzz) : int_vec[7:0]; // Set INT IM 2 vector to INT_VEC or set D to DO when OutEnable
	
	assign nCONCS = ~(nIORQ == 0 && nM1 == 1 && A[7:3] == 5'b00001); // Port 0x08..0x0f 8251 Select
	assign nRAMCS = nMREQ | ~EXT_A[5];
	assign nROMCS = nMREQ | EXT_A[5];

//	assign nWAIT = 1'b1;
	assign nNMI = 1'b1;
	assign nINT = ~PS2_int;//~CONIRQ & ~PS2_int;
	assign nRESET = ~res;
	assign RESET = res;

endmodule