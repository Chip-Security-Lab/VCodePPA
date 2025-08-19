//SystemVerilog
module crossbar_arbiter #(parameter N=4) (
  input wire clk, rst,
  input wire [N-1:0] src_req,
  input wire [N-1:0] dst_sel [N-1:0],
  output reg [N-1:0] src_gnt,
  output reg [N-1:0] dst_gnt [N-1:0]
);
  integer i, j;
  
  // Pipeline registers
  reg [N-1:0] src_req_r;
  reg [N-1:0] dst_sel_r [N-1:0];
  reg [N-1:0] dst_gnt_stage1 [N-1:0];
  reg [N-1:0] src_gnt_stage1;
  
  // First stage: Register inputs
  always @(posedge clk) begin
    if (rst) begin
      src_req_r <= 0;
      for (i = 0; i < N; i = i + 1) dst_sel_r[i] <= 0;
    end else begin
      src_req_r <= src_req;
      for (i = 0; i < N; i = i + 1) dst_sel_r[i] <= dst_sel[i];
    end
  end
  
  // Second stage: Process first half of arbitration logic
  always @(posedge clk) begin
    if (rst) begin
      src_gnt_stage1 <= 0;
      for (i = 0; i < N; i = i + 1) dst_gnt_stage1[i] <= 0;
    end else begin
      src_gnt_stage1 <= 0;
      for (i = 0; i < N; i = i + 1) dst_gnt_stage1[i] <= 0;
      
      for (i = 0; i < N; i = i + 1) begin
        if (src_req_r[i]) begin
          for (j = 0; j < N; j = j + 1) begin
            if (dst_sel_r[i][j] && !dst_gnt_stage1[j]) begin
              src_gnt_stage1[i] <= 1'b1;
              dst_gnt_stage1[j] <= 1'b1;
            end
          end
        end
      end
    end
  end
  
  // Final stage: Update outputs
  always @(posedge clk) begin
    if (rst) begin
      src_gnt <= 0;
      for (i = 0; i < N; i = i + 1) dst_gnt[i] <= 0;
    end else begin
      src_gnt <= src_gnt_stage1;
      for (i = 0; i < N; i = i + 1) dst_gnt[i] <= dst_gnt_stage1[i];
    end
  end
endmodule