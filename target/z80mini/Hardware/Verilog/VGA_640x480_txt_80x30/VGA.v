module VGA
(
	input  wire	CLK_50,
	output wire H_Sync,
	output wire V_Sync,
	output wire	VGA_R,
	output wire VGA_G,
	output wire VGA_B,
	output wire VGA_I,
	output wire [14:0] RAM_A,
	inout	 wire [7:0] RAM_D,
	output wire RAM_nWE,
	output wire RAM_nOE,
	input  wire [14:0] CPU_A,
	inout  wire [7:0] CPU_D,
	input  wire	CPU_nWR
);

	reg [9:0] X; // 0..799
	reg [9:0] Y; // 0..524
	reg [7:0] char;
	reg [7:0] attr;
	reg [7:0] char_out;
	reg [7:0] attr_out;
	reg [14:0] cpu_addr;
	reg [7:0] cpu_data;

	reg div = 1'b0;
	
	localparam
		h_visible = 640,	h_front_porch = 16,	h_sync_pulse = 96,	h_back_porch = 48,	h_max = 10'd800,	hshift = 8,
		v_visible = 480,	v_front_porch = 10,	v_sync_pulse = 2,		v_back_porch = 33,	v_max = 10'd525,	vshift = 0;

	reg [1:0] wr_valid = 2'b00; //????

	always @(posedge CLK_50) begin
		if (~div) begin

			X <= X == h_max - 10'd1 ? 10'd0 : (X + 10'd1);
			Y <= X == h_max - 10'd1 ? (Y == v_max - 10'd1 ? 10'd0 : Y + 10'd1) : Y;
			
			case (wr_valid)
			0 : wr_valid <= CPU_nWR ? wr_valid : 2'd1;
			1 : begin wr_valid <= 2'd2; cpu_addr <= CPU_A; cpu_data <= CPU_D; end
			2 : wr_valid <= |X[2:0] ? wr_valid : 2'd3;
			3 : wr_valid <= |X[2:0] ? wr_valid : 2'd0;
			endcase

			case (X[2:0])
			1, 5	: char[7:0] <= RAM_D;
			3		: attr[7:0] <= RAM_D;
			7		: begin
						char_out[7:0] <= char[7:0];
						attr_out[7:0] <= attr[7:0];
					end
			endcase

		end
		div <= ~div;
	end

	
	wire window = 1'b0;
	wire [1:0] charset = 2'b00;
	wire ram_we = (X[2:1] == 2'd3 && &wr_valid[1:0]);
	
	assign RAM_A[14:0] = ram_we ? cpu_addr : X[2] ? {charset[1], 1'b1, charset[1], char[7:0], Y[3:0]} : {window, 1'b0, X[1], Y[8:4], X[9:3]}; 
	assign RAM_D = ram_we ? cpu_data : 8'b_zzzz_zzzz;
	assign RAM_nWE = ~ram_we;
	assign RAM_nOE = ram_we;

	assign H_Sync = (X < h_visible + h_front_porch + hshift)	|| (X >= h_max - h_back_porch + hshift);
	assign V_Sync = (Y < v_visible + v_front_porch + vshift) || (Y >= v_max - v_back_porch + vshift);

	wire visible =	(X >= hshift) && (X < h_visible + hshift) && 
						(Y >= vshift) && (Y < v_visible + vshift);


	// -----------------------------------------------------------------------------
	assign VGA_R = visible && char_out[~X[2:0]] ? attr_out[0] : attr_out[4];
	assign VGA_B = visible && char_out[~X[2:0]] ? attr_out[1] : attr_out[5];
	assign VGA_G = visible && char_out[~X[2:0]] ? attr_out[2] : attr_out[6];
	assign VGA_I = visible && char_out[~X[2:0]] ? attr_out[3] : attr_out[7];
	// -----------------------------------------------------------------------------
endmodule