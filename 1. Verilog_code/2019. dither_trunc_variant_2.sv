//SystemVerilog
module dither_trunc #(
    parameter W = 16
)(
    input  wire [W+3:0] in,
    output wire [W-1:0] out
);

// ==========================
// Pipeline Stage 1: LFSR Update (moved after dither compare)
// ==========================

// ==========================
// Pipeline Stage 1: Input Latching (moved after dither compare)
// ==========================

// ==========================
// Pipeline Stage 1: Dither Calculation (new Stage 1)
// ==========================
wire [2:0] lfsr_stage1_comb;
wire [W+3:0] in_stage2_comb;
wire [W-1:0] trunc_result_stage3_comb;
wire dither_bit_stage3_comb;

assign lfsr_stage1_comb        = {lfsr_stage1_reg[1:0], lfsr_stage1_reg[2] ^ lfsr_stage1_reg[1]};
assign in_stage2_comb          = in;
assign trunc_result_stage3_comb = in[W+3:4];
assign dither_bit_stage3_comb   = (in[3:0] > lfsr_stage1_reg);

// ==========================
// Pipeline Stage 2: Register all signals after combination
// ==========================
reg [2:0] lfsr_stage1_reg;
reg [W+3:0] in_stage2_reg;
reg [W-1:0] trunc_result_stage3_reg;
reg dither_bit_stage3_reg;

always @(posedge in[0]) begin
    lfsr_stage1_reg           <= lfsr_stage1_comb;
    in_stage2_reg             <= in_stage2_comb;
    trunc_result_stage3_reg   <= trunc_result_stage3_comb;
    dither_bit_stage3_reg     <= dither_bit_stage3_comb;
end

// ==========================
// Pipeline Stage 3: Output Calculation (unchanged)
// ==========================
reg [W-1:0] out_stage4;
always @(posedge in[0]) begin
    out_stage4 <= trunc_result_stage3_reg + dither_bit_stage3_reg;
end

assign out = out_stage4;

endmodule