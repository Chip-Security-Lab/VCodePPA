//SystemVerilog
// Top level module
module reset_sync_asynch (
  input  wire clk,
  input  wire arst_n,
  output wire rst_sync
);
  
  // Internal connection signals
  wire sync_stage1_out;
  
  // Clock and reset buffering for fanout reduction
  wire clk_buf1, clk_buf2;
  wire arst_n_buf1, arst_n_buf2;
  
  // Clock buffer distribution
  assign clk_buf1 = clk;
  assign clk_buf2 = clk;
  
  // Asynchronous reset buffer distribution
  assign arst_n_buf1 = arst_n;
  assign arst_n_buf2 = arst_n;
  
  // First synchronization stage
  reset_stage1 u_stage1 (
    .clk          (clk_buf1),
    .arst_n       (arst_n_buf1),
    .stage1_out   (sync_stage1_out)
  );
  
  // Second synchronization stage
  reset_stage2 u_stage2 (
    .clk          (clk_buf2),
    .arst_n       (arst_n_buf2),
    .stage1_in    (sync_stage1_out),
    .rst_sync_out (rst_sync)
  );
  
endmodule

// First stage of the reset synchronizer
module reset_stage1 (
  input  wire clk,
  input  wire arst_n,
  output reg  stage1_out
);
  
  // Local buffering for better timing
  reg local_reset_n;
  
  always @(posedge clk or negedge arst_n) begin
    if (!arst_n) begin
      local_reset_n <= 1'b0;
    end else begin
      local_reset_n <= 1'b1;
    end
  end
  
  always @(posedge clk or negedge local_reset_n) begin
    if (!local_reset_n) begin
      stage1_out <= 1'b0;
    end else begin
      stage1_out <= 1'b1;
    end
  end
  
endmodule

// Second stage of the reset synchronizer
module reset_stage2 (
  input  wire clk,
  input  wire arst_n,
  input  wire stage1_in,
  output reg  rst_sync_out
);
  
  // Local buffering for better timing
  reg local_reset_n;
  
  always @(posedge clk or negedge arst_n) begin
    if (!arst_n) begin
      local_reset_n <= 1'b0;
    end else begin
      local_reset_n <= 1'b1;
    end
  end
  
  always @(posedge clk or negedge local_reset_n) begin
    if (!local_reset_n) begin
      rst_sync_out <= 1'b0;
    end else begin
      rst_sync_out <= stage1_in;
    end
  end
  
endmodule