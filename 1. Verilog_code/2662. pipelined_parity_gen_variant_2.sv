//SystemVerilog
module pipelined_parity_gen(
  input clk, rst_n,
  input [31:0] data_in,
  output reg parity_out
);
  // Use tree-based approach for parity calculation
  reg [7:0] stage1_parity;
  reg [1:0] stage2_parity;
  
  always @(posedge clk) begin
    if (!rst_n) begin
      stage1_parity <= 8'b0;
      stage2_parity <= 2'b0;
      parity_out <= 1'b0;
    end else begin
      // First stage: compute parity for 4-bit groups
      stage1_parity[0] <= ^data_in[3:0];
      stage1_parity[1] <= ^data_in[7:4];
      stage1_parity[2] <= ^data_in[11:8];
      stage1_parity[3] <= ^data_in[15:12];
      stage1_parity[4] <= ^data_in[19:16];
      stage1_parity[5] <= ^data_in[23:20];
      stage1_parity[6] <= ^data_in[27:24];
      stage1_parity[7] <= ^data_in[31:28];
      
      // Second stage: combine parity of 4 groups each
      stage2_parity[0] <= ^stage1_parity[3:0];
      stage2_parity[1] <= ^stage1_parity[7:4];
      
      // Final stage: combine parity of entire word
      parity_out <= ^stage2_parity;
    end
  end
endmodule