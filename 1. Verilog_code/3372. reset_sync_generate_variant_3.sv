//SystemVerilog
module reset_sync_generate #(
  parameter NUM_STAGES = 4  // 增加默认流水线级数从2到4
)(
  input  wire clk,
  input  wire rst_n,
  output wire synced
);
  
  // 增加流水线深度，添加更多寄存器以降低每级延迟
  reg [NUM_STAGES-1:0] chain_stage1;
  reg [NUM_STAGES-1:0] chain_stage2;
  reg synced_internal;
  
  // 第一级流水线阶段
  genvar i;
  generate
    for(i=0; i<NUM_STAGES; i=i+1) begin : sync_stages_pipe1
      always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          chain_stage1[i] <= 1'b0;
        end
        else if(i==0) begin
          chain_stage1[i] <= 1'b1;
        end
        else begin
          chain_stage1[i] <= chain_stage1[i-1];
        end
      end
    end
  endgenerate
  
  // 第二级流水线阶段 - 增加流水线深度
  genvar j;
  generate
    for(j=0; j<NUM_STAGES; j=j+1) begin : sync_stages_pipe2
      always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          chain_stage2[j] <= 1'b0;
        end
        else if(j==0) begin
          chain_stage2[j] <= chain_stage1[NUM_STAGES-1];
        end
        else begin
          chain_stage2[j] <= chain_stage2[j-1];
        end
      end
    end
  endgenerate
  
  // 输出寄存器 - 进一步分割关键路径
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      synced_internal <= 1'b0;
    end
    else begin
      synced_internal <= chain_stage2[NUM_STAGES-1];
    end
  end
  
  // 输出复位同步信号
  assign synced = synced_internal;
  
endmodule