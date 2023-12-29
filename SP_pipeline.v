module SP_pipeline(
	// INPUT SIGNAL
	clk,
	rst_n,
	in_valid,
	inst,
	mem_dout,
	// OUTPUT SIGNAL
	out_valid,
	inst_addr,
	mem_wen,
	mem_addr,
	mem_din
);



//------------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//------------------------------------------------------------------------

input                    clk, rst_n, in_valid;
input             [31:0] inst;
input  signed     [31:0] mem_dout;
output reg               out_valid;
output reg        [31:0] inst_addr;
output reg               mem_wen;
output reg        [11:0] mem_addr;
output reg signed [31:0] mem_din;

//------------------------------------------------------------------------
//   DECLARATION
//------------------------------------------------------------------------

// REGISTER FILE, DO NOT EDIT THE NAME.
reg	signed [31:0] r [0:31]; 

reg signed [31:0] r_nxt [0:31];
integer i; // for reg loop

reg out_valid_buf;
wire out_valid_nxt;
reg [31:0] inst_addr_nxt;

reg [31:0] inst_reg;
wire [31:0] inst_nxt;

// R type
wire [5:0] opcode, func;
wire [5:0] opcode_reg, func_reg;
wire [4:0] rs, rt, rd, shamt;
wire [4:0] rs_reg, rt_reg, rd_reg, shamt_reg;

// I type
wire [15:0] imme, imme_reg;
wire [31:0] ZE, SE, ZE_reg, SE_reg;

// Jump
wire [25:0] jump_addr, jump_addr_reg;

reg signed [31:0] ALU_out_reg;
reg signed [31:0] ALU_out, ALU_op1, ALU_op2;

// store inst addr for 1 cycle
reg [31:0] inst_addr_reg;


//------------------------------------------------------------------------
//   DESIGN
//------------------------------------------------------------------------

assign inst_nxt = (in_valid) ? inst : inst_reg;

assign opcode = inst_nxt[31:26];
assign opcode_reg = inst_reg[31:26];
assign rs = inst_nxt[25:21];
assign rs_reg = inst_reg[25:21];
assign rt = inst_nxt[20:16];
assign rt_reg = inst_reg[20:16];
assign rd = inst_nxt[15:11];
assign rd_reg = inst_reg[15:11];
assign shamt = inst_nxt[10:6];
assign shamt_reg = inst_reg[10:6];
assign func = inst_nxt[5:0];
assign func_reg = inst_reg[5:0];
assign imme = inst_nxt[15:0];
assign imme_reg = inst_reg[15:0];
assign ZE = {16'd0, imme};
assign ZE_reg = {16'd0, imme_reg};
assign SE = {{16{imme[15]}}, imme};
assign SE_reg = {{16{imme_reg[15]}}, imme_reg};
assign jump_addr = inst_nxt[25:0];
assign jump_addr_reg = inst_reg[25:0];

// PC
always@(*) begin
	inst_addr_nxt = inst_addr;
	if (in_valid) begin
		inst_addr_nxt = inst_addr + 4;
	end
	if (out_valid_buf) begin
		case(opcode)
			0: if (func == 7) inst_addr_nxt = r[rs]; // jr
			7, 8: inst_addr_nxt = (ALU_out)? inst_addr + 4 + {{14{imme[15]}},imme, 2'b0} : inst_addr + 4; // beq, bne
			10, 11: inst_addr_nxt = {inst_addr[31:28], jump_addr, 2'b0}; // j, jal
		endcase
	end
end

// ALU
always@(*) begin
	ALU_op1 = r[rs];
	ALU_op2 = 0;
	case(opcode)
		0, 7, 8: ALU_op2 = r[rt];
		1, 2: ALU_op2 = ZE;
		3, 4, 5, 6: ALU_op2 = SE;
	endcase
end

always@(*) begin
	ALU_out = 0;
	if (in_valid) begin
		case(opcode)
			// R type
			0: begin
				case(func)
					0: ALU_out = ALU_op1 & ALU_op2;
					1: ALU_out = ALU_op1 | ALU_op2;
					2: ALU_out = ALU_op1 + ALU_op2;
					3: ALU_out = ALU_op1 - ALU_op2;
					4: ALU_out = ALU_op1 < ALU_op2;
					5: ALU_out = ALU_op1 << shamt;
					6: ALU_out = ~(ALU_op1 | ALU_op2);
				endcase
			end
			// I type
			1: ALU_out = ALU_op1 & ALU_op2;
			2: ALU_out = ALU_op1 | ALU_op2;
			3: ALU_out = ALU_op1 + ALU_op2;
			4: ALU_out = ALU_op1 - ALU_op2;
			5, 6: ALU_out = ALU_op1 + ALU_op2; // lw, sw
			7: ALU_out = ALU_op1 == ALU_op2; // beq
			8: ALU_out = ALU_op1 != ALU_op2; // bne
		endcase
	end
end

// regiter
always@(*) begin
	for (i=0; i<32; i=i+1)
		r_nxt[i] = r[i];
	if(out_valid_buf) begin
		case(opcode_reg)
			0: if(func_reg != 7) r_nxt[rd_reg] = ALU_out_reg;
			1, 2, 3, 4: r_nxt[rt_reg] = ALU_out_reg;
			5: r_nxt[rt_reg] = mem_dout;
			9: r_nxt[rt_reg] = {imme_reg, 16'd0};
			11: r_nxt[31] = inst_addr_reg + 4;
		endcase
	end
end

// memory
always@(*) begin
	mem_wen = 1;
	mem_addr = ALU_out;
	mem_din = 0;
	if(in_valid && (opcode == 6)) begin
		mem_wen = 0;
		mem_din = r[rt];
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_valid <= 0;
		out_valid_buf <= 0;
		inst_addr <= 0;
		inst_addr_reg <= 0;
		for (i=0; i<32; i=i+1) begin
			r[i] <= 0;
		end
		inst_reg <= 0;
		ALU_out_reg <= 0;
	end
	else begin
		out_valid <= out_valid_buf; // delay 1 cycle
		out_valid_buf <= in_valid;
		inst_addr <= inst_addr_nxt;
		inst_addr_reg <= inst_addr;
		for (i=0; i<32; i=i+1) begin
			r[i] <= r_nxt[i];
		end
		inst_reg <= inst_nxt;
		ALU_out_reg <= ALU_out;
	end
end


endmodule