//SystemVerilog
module masked_shifter (
  input  wire [31:0] data_in,
  input  wire [31:0] mask,
  input  wire [4:0]  shift,
  output wire [31:0] data_out
);

  wire [31:0] stage0_mux0, stage0_mux1;
  wire [31:0] stage1_mux0, stage1_mux1;
  wire [31:0] stage2_mux0, stage2_mux1;
  wire [31:0] stage3_mux0, stage3_mux1;
  wire [31:0] stage4_mux0, stage4_mux1;
  wire [31:0] stage0_out, stage1_out, stage2_out, stage3_out, stage4_out;
  wire [31:0] shifted_data;
  wire [31:0] masked_shifted, masked_original;

  // Stage 0: shift by 1 if shift[0] is set
  assign stage0_mux1 = {data_in[30:0], 1'b0};
  assign stage0_mux0 = data_in;
  assign stage0_out = shift[0] ? stage0_mux1 : stage0_mux0;

  // Stage 1: shift by 2 if shift[1] is set
  assign stage1_mux1 = {stage0_out[29:0], 2'b00};
  assign stage1_mux0 = stage0_out;
  assign stage1_out = shift[1] ? stage1_mux1 : stage1_mux0;

  // Stage 2: shift by 4 if shift[2] is set
  assign stage2_mux1 = {stage1_out[27:0], 4'b0000};
  assign stage2_mux0 = stage1_out;
  assign stage2_out = shift[2] ? stage2_mux1 : stage2_mux0;

  // Stage 3: shift by 8 if shift[3] is set
  assign stage3_mux1 = {stage2_out[23:0], 8'b0000_0000};
  assign stage3_mux0 = stage2_out;
  assign stage3_out = shift[3] ? stage3_mux1 : stage3_mux0;

  // Stage 4: shift by 16 if shift[4] is set
  assign stage4_mux1 = {stage3_out[15:0], 16'b0};
  assign stage4_mux0 = stage3_out;
  assign stage4_out = shift[4] ? stage4_mux1 : stage4_mux0;

  assign shifted_data = stage4_out;

  assign masked_shifted = shifted_data & mask;
  assign masked_original = data_in & ~mask;
  assign data_out = masked_shifted | masked_original;

endmodule