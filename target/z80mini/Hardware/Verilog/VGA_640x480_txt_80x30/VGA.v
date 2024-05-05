module VGA
(
	input  wire	CLK_25,
	output wire H_Sync, V_Sync, VGA_R, VGA_G, VGA_B, VGA_I,
	output wire [13:0] RAM_A,
	inout	 wire [7:0] RAM_D,
	output wire RAM_nWE, RAM_nOE,
	input  wire [14:0] CPU_A,
	input  wire [7:0] CPU_D,
	input  wire	CPU_nWR,
	input  wire	CPU_nRD,
	input  wire	Foo
);
	reg [9:0] X; // 0..799
	reg [9:0] Y; // 0..524
	reg [7:0] char;
	reg [7:0] attr;
	reg [7:0] char_out;
	reg [7:0] attr_out;
	reg [13:0] cpu_addr;
	reg [7:0] cpu_data;
	reg [7:0] cpu_attr;
	reg [1:0] fsmr = 2'b00;
	reg [1:0] fsmw = 2'b00;

// 0 00 -- idle
// 1 01 -- wait wr
// 2 10 -- write1
// 3 11 -- write2
	
	localparam
		h_visible = 640,	h_front_porch = 16,	h_sync_pulse = 96,	h_back_porch = 48,	h_max = 10'd800,	hshift = 8,
		v_visible = 480,	v_front_porch = 10,	v_sync_pulse = 2,		v_back_porch = 33,	v_max = 10'd525,	vshift = 0;

	always @(posedge CLK_25) begin
		X <= X == h_max - 10'd1 ? 10'd0 : (X + 10'd1);
		Y <= X == h_max - 10'd1 ? (Y == v_max - 10'd1 ? 10'd0 : Y + 10'd1) : Y;

		case (fsmw)
			0 : if (~CPU_nWR) begin // idle
					fsmw <= 2'd1;
					//cpu_addr <= CPU_A[13:0];
					//cpu_data <= CPU_D;
					//cpu_attr <= CPU_A[13:12] == 2'b01 ? CPU_D : cpu_attr;
				end
			1 : 	begin
					fsmw <= 2'd2;
					cpu_addr <= CPU_A[13:0];
					cpu_data <= CPU_D;
					cpu_attr <= CPU_A[13:12] == 2'b01 ? CPU_D : cpu_attr;
				end

//			1 : fsmw <= X[2:0] == 5 ? 2'd2 : fsmw; // wait wr
			2 : fsmw <= X[2:0] == 7 ? 2'd3 : fsmw; // write1
			3 : fsmw <= X[2:0] == 7 ? 2'd0 : fsmw; // write2
		endcase

		case (fsmr)
			0 : if (~CPU_nRD) begin //idle
					fsmr <= 2'd1;
					cpu_addr <= CPU_A[13:12] == 2'b00 ? {CPU_A[13], 1'b1, CPU_A[11:0]} : CPU_A[13:0];
				end
			1 : fsmr <= X[2:0] == 5 ? 2'd3 : fsmr; // wait rd
			3 : if (X[2:0] == 7) begin  // read
					fsmr <= 2'd0;
					cpu_attr <= cpu_addr[13:12] == 2'b01 ? RAM_D : cpu_attr;
				end
		endcase

		case (X[2:0])
			1, 5	: char[7:0] <= RAM_D;
			3		: attr[7:0] <= RAM_D;
			7		: begin char_out[7:0] <= char[7:0]; attr_out[7:0] <= attr[7:0]; end
		endcase
	end

	wire ram_wr = &X[2:1] && fsmw[1];

	wire cset = 1'b0;

	wire [13:0] wr_addr = X[3] && cpu_addr[13:12] == 2'b00 ? {2'b01, cpu_addr[11:0]} : cpu_addr;
	wire [13:0] rd_addr = X[2] ? {1'b1, cset, char[7:0], Y[3:0]} : {1'b0, X[1], Y[8:4], X[9:3]};

	//assign RAM_A[14] = 1'b0;
	//assign RAM_A[13:0] = ram_wr ? wr_addr : rd_addr;
	assign RAM_A[13:0] = &X[2:1] ? wr_addr : rd_addr;

	wire [7:0] wr_data = X[3] && cpu_addr[13:12] == 2'b00 ? cpu_attr : cpu_data;
	assign RAM_D = ram_wr ? wr_data : 8'b_zzzz_zzzz;
						
	
	assign RAM_nWE = ~ram_wr;
	assign RAM_nOE = ram_wr;
	
	
	
	
	assign H_Sync = (X < h_visible + h_front_porch + hshift)	|| (X >= h_max - h_back_porch + hshift);
	assign V_Sync = (Y < v_visible + v_front_porch + vshift) || (Y >= v_max - v_back_porch + vshift);

	wire visible =	(X >= hshift) && (X < h_visible + hshift) && 
						(Y >= vshift) && (Y < v_visible + vshift);


	// -----------------------------------------------------------------------------
	assign VGA_R = visible && char_out[~X[2:0]] ? attr_out[0] : attr_out[4];
	assign VGA_G = visible && char_out[~X[2:0]] ? attr_out[1] : attr_out[5];
	assign VGA_B = visible && char_out[~X[2:0]] ? attr_out[2] : attr_out[6];
	assign VGA_I = visible && char_out[~X[2:0]] ? attr_out[3] : attr_out[7];
	// -----------------------------------------------------------------------------
endmodule