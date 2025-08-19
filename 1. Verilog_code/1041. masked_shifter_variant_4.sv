//SystemVerilog
module masked_shifter (
  input  [31:0] data_in,
  input  [31:0] mask,
  input  [4:0]  shift,
  output [31:0] data_out
);
  wire [31:0] shift_stage_0;
  wire [31:0] shift_stage_1;
  wire [31:0] shift_stage_2;
  wire [31:0] shift_stage_3;
  wire [31:0] shift_stage_4;
  wire [31:0] shifted_data;

  // Stage 0: Shift by 1 if shift[0]
  assign shift_stage_0 = shift[0] ? {data_in[30:0], 1'b0} : data_in;
  // Stage 1: Shift by 2 if shift[1]
  assign shift_stage_1 = shift[1] ? {shift_stage_0[29:0], 2'b00} : shift_stage_0;
  // Stage 2: Shift by 4 if shift[2]
  assign shift_stage_2 = shift[2] ? {shift_stage_1[27:0], 4'b0000} : shift_stage_1;
  // Stage 3: Shift by 8 if shift[3]
  assign shift_stage_3 = shift[3] ? {shift_stage_2[23:0], 8'b00000000} : shift_stage_2;
  // Stage 4: Shift by 16 if shift[4]
  assign shift_stage_4 = shift[4] ? {shift_stage_3[15:0], 16'b0} : shift_stage_3;

  assign shifted_data = shift_stage_4;
  assign data_out = (mask & shifted_data) | (~mask & data_in);
endmodule