//SystemVerilog
module reset_sync_no_latch(
  input  wire clk,
  input  wire rst_n,
  output reg  synced
);
  reg rst_n_stage1;
  reg rst_n_stage2;
  reg rst_n_stage3;
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      rst_n_stage1 <= 1'b0;
    end else begin
      rst_n_stage1 <= 1'b1;
    end
  end
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      rst_n_stage2 <= 1'b0;
    end else begin
      rst_n_stage2 <= rst_n_stage1;
    end
  end
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      rst_n_stage3 <= 1'b0;
    end else begin
      rst_n_stage3 <= rst_n_stage2;
    end
  end
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      synced <= 1'b0;
    end else begin
      synced <= rst_n_stage3;
    end
  end
endmodule