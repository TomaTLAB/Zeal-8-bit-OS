module z80mini(
	input wire CLK50MHz,
	input wire [15:0] A,
	inout wire [7:0] D,
	input wire nMREQ, nIORQ, nWR, nRD, nM1, nRES, nHALT, CONIRQ,
	inout wire nWAIT, nINT, nNMI,
	output wire CPUCLK, nRESET,
	output wire CONCLK, TCLK, RESET, nCONCS,
	output wire nRAMCS, nROMCS,
	output wire [5:0] EXT_A,
	inout wire RS, RW, E,
	inout wire [7:0] EXT_P
);

	wire [7:0] do;
	wire [7:0] int_vec;
	
	wire vid_nwr;
	wire map_cs;
	wire ext_cs;
	wire ps2_cs;
	wire oe;
	wire io_wt;
	wire [7:0] PS2_data_out;
	wire PS2_tim;
	wire PS2_irq;
	wire CPUCLK0;

	reg [5:0] mapper [0:3];
	reg div;
	
	frequency_generator fg0 (
		.clock_in(CLK50MHz),
		.cpu_clk(CPUCLK), .cpu_clk0(CPUCLK0), .t_clk(TCLK), .con_clk(CONCLK), .con_clk0(PS2_tim)
	);
	//assign TCLK = CPUCLK;
	
	signal_conditioner res_con(
		.clk(CLK50MHz), .clk0(CPUCLK0), .sig_in(nRES),
		.sig_out(nRESET)
	);
	assign RESET = ~nRESET;
	
	

	//IO_wait iow0 (
	//   .clk(CLK50MHz), .clk0(CPUCLK0), .n_res(nRESET), .n_iorq(nCONCS), //.n_iorq(nIORQ), //Waitstate for 8251 etc.
	//	.io_wt(io_wt) 
	//);
	//assign nWAIT = io_wt ? 1'b0 : 1'bz;
	assign nWAIT = 1'bz;
		
	assign nCONCS = ~(nIORQ == 0 && nM1 == 1 && A[7:4] == 4'h0 && A[3] == 1'b1); // Port 0x08..0x0f 8251 Select
//	assign nCONCS = nIORQ | ~nM1 | |A[7:4] | ~A[3]; // Port 0x08..0x0f 8251 Select
	assign vid_nwr = ~(nMREQ == 0 && nWR == 0 && EXT_A[5:4] == 2'b01); //hardwire 256K VRAM to 0x040000..0x08FFFF
//	assign vid_nwr = nMREQ | nWR | EXT_A[5] | ~EXT_A[4]; //hardwire 256K VRAM to 0x040000..0x08FFFF
	assign ext_cs = (A[7:4] == 4'hD) && (A[1:0] == 2'b01);
	assign ps2_cs = (A[7:4] == 4'hE); // [0xE0..EF]
	assign map_cs = (A[7:4] == 4'hF); // [0xF0..F3]...[0xFC..FF]

	PS2_receiver ps2r(
		.clk(CLK50MHz), .clk0(CPUCLK0), .n_res(nRESET), .ps2_clock(EXT_P[7]), .ps2_data(EXT_P[4]), .ps2_ack(nIORQ == 0 && nRD == 0 && ps2_cs), .tim_clk(PS2_tim),
		.ps2_done(PS2_irq), .ps2_out(PS2_data_out)
	);

	assign oe = ~(nRD | nIORQ) & (ps2_cs | ext_cs | map_cs);

	assign do[7:0] = 	ps2_cs ?	PS2_data_out[7:0] : 
							ext_cs ?	{~PS2_irq,	// KB SIGNAL
										 1'b1,		// V-SYNC IN
										 1'b1,		// H-SYNC IN
										 1'b1,		// soft UART TX
										 EXT_P[3],	// soft UART RX
										 EXT_P[5],	// I2C SDA IN
										 1'b1,		// I2C SCL OUT
										 1'b1			// I2C SDA OUT
										 } : 
							map_cs ?	{2'b11, mapper[A[15:14]][5:0]} : // mapper read addressed by 2 MSB of CPU address bus 
										8'hFF; // set data bus to 0xFF if address missdecoded for any reason...

	assign int_vec[7:0] = 8'h02;

	assign D[7:0] = ~nM1 & ~nIORQ	?	int_vec[7:0] : // Set data bus INT IM 2 vector when int req
										oe	?	do[7:0] : 		// or set dataout when OutEnable
												8'bzzzzzzzz;	// or set HiZ otherwise
	reg sda, scl, s_tx;

   always @(posedge CLK50MHz) begin
		if (~nRESET) begin
			mapper[0][5:0] <= 8'h00; // 0x000000 
			mapper[1][5:0] <= 8'h20; // 0x080000
			mapper[2][5:0] <= 8'h21; // 0x084000
			mapper[3][5:0] <= 8'h22; // 0x088000
		end else begin
			div <= ~div;
			if (CPUCLK0 && (nIORQ == 0 && nWR == 0 && map_cs)) begin
				mapper[A[1:0]][5:0] <= D[5:0]; // mapper write addressed by 2 LSB of CPU address bus 
			end
			if (CPUCLK0 && (nIORQ == 0 && nWR == 0 && ext_cs)) begin
				sda <= D[0]; scl <= D[1]; s_tx <= D[4];
			end
		end
	end

	assign EXT_A[5:0] = mapper[A[15:14]][5:0];

	assign nROMCS = nMREQ || |EXT_A[5:4];	//hardwire 256K ROM to 0x000000..0x03FFFF exactly. No mirrors!
	assign nRAMCS = nMREQ || ~EXT_A[5];		//hardwire 512K RAM to 0x080000..0x0FFFFF

	assign nNMI = 1'bz;
	//assign nINT = PS2_irq | CONIRQ ? 1'b0 : 1'bz;
	assign nINT = PS2_irq ? 1'b0 : 1'bz;
	
	assign EXT_P[0] = 1'b0;
	assign EXT_P[1] = 1'b0;
	assign EXT_P[2] = s_tx ? 1'bz : 1'b0;	// Soft UART TX
	assign EXT_P[3] = 1'bz;						// Soft UART RX
	assign EXT_P[4] = 1'bz;						// PS/2 Data input
	assign EXT_P[5] = sda ? 1'bz : 1'b0;	// I2C SDA
	assign EXT_P[6] = scl ? 1'bz : 1'b0;	// I2C SCL
	assign EXT_P[7] = 1'bz;						// PS/2 Clock input

	assign RS = vid_nwr; //1'b0;
	assign RW = 1'b0;
	assign E = div; //1'b0;
	
endmodule