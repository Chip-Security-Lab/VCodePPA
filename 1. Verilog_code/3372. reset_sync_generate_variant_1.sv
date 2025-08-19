//SystemVerilog
module reset_sync_generate #(parameter NUM_STAGES=2)(
  input  wire clk,
  input  wire rst_n,
  output wire synced
);
  reg [NUM_STAGES-1:0] chain;
  reg [NUM_STAGES-2:0] chain_buf1;
  reg [NUM_STAGES-2:0] chain_buf2;
  
  // 第一级寄存器移至组合逻辑之后
  wire first_stage_input = 1'b1;
  
  genvar i;
  generate
    for(i=0; i<NUM_STAGES; i=i+1) begin : sync_stages
      always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          chain[i] <= 1'b0;
          if(i < NUM_STAGES-1) begin
            chain_buf1[i] <= 1'b0;
            chain_buf2[i] <= 1'b0;
          end
        end
        else if(i==0) begin
          // 第一级寄存器现在使用组合逻辑之后的值
          chain[i] <= first_stage_input;
        end
        else begin
          // 后续阶段的寄存器连接保持不变
          chain[i] <= chain_buf2[i-1];
          if(i < NUM_STAGES-1) begin
            // 缓冲路径优化：减少扇出负载影响
            chain_buf1[i-1] <= chain[i-1];
            chain_buf2[i-1] <= chain_buf1[i-1];
          end
        end
      end
    end
  endgenerate
  
  assign synced = chain[NUM_STAGES-1];
endmodule