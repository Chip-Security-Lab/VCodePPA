module pipelined_parity_gen(
  input clk, rst_n,
  input [31:0] data_in,
  output reg parity_out
);
  reg [15:0] stage1_data;
  reg stage1_parity_lo, stage1_parity_hi;
  
  always @(posedge clk) begin
    if (!rst_n) begin
      stage1_parity_lo <= 1'b0;
      stage1_parity_hi <= 1'b0;
      parity_out <= 1'b0;
    end else begin
      stage1_parity_lo <= ^data_in[15:0];
      stage1_parity_hi <= ^data_in[31:16];
      parity_out <= stage1_parity_lo ^ stage1_parity_hi;
    end
  end
endmodule