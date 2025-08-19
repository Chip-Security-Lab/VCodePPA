module pipelined_barrel_shifter (
  input clk, rst,
  input [31:0] data_in,
  input [4:0] shift,
  output reg [31:0] data_out
);
  reg [31:0] stage1, stage2;
  
  always @(posedge clk) begin
    if (rst) begin
      stage1 <= 0; stage2 <= 0; data_out <= 0;
    end else begin
      // 3-stage pipeline for large shifts
      stage1 <= shift[4] ? {data_in[15:0], 16'b0} : data_in;
      stage2 <= shift[3] ? {stage1[23:0], 8'b0} : stage1;
      data_out <= shift[2:0] ? stage2 << shift[2:0] : stage2;
    end
  end
endmodule