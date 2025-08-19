//SystemVerilog
module reset_sync_init_val #(parameter INIT_VAL=1'b0)(
  input  wire clk,
  input  wire rst_n,
  input  wire data_valid_in,   // 输入数据有效信号
  output wire data_valid_out,  // 输出数据有效信号
  output reg  rst_sync
);
  
  // 增加流水线深度，从2级扩展到4级
  reg flop_stage1;
  reg flop_stage2;
  reg flop_stage3;
  reg flop_stage4;
  
  reg valid_stage1;
  reg valid_stage2;
  reg valid_stage3;
  reg valid_stage4;
  
  // 第一级流水线
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      flop_stage1 <= INIT_VAL;
      valid_stage1 <= 1'b0;
    end else begin
      flop_stage1 <= ~INIT_VAL;
      valid_stage1 <= data_valid_in;
    end
  end
  
  // 第二级流水线
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      flop_stage2 <= INIT_VAL;
      valid_stage2 <= 1'b0;
    end else begin
      flop_stage2 <= flop_stage1;
      valid_stage2 <= valid_stage1;
    end
  end
  
  // 增加第三级流水线
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      flop_stage3 <= INIT_VAL;
      valid_stage3 <= 1'b0;
    end else begin
      flop_stage3 <= flop_stage2;
      valid_stage3 <= valid_stage2;
    end
  end
  
  // 增加第四级流水线
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      flop_stage4 <= INIT_VAL;
      valid_stage4 <= 1'b0;
    end else begin
      flop_stage4 <= flop_stage3;
      valid_stage4 <= valid_stage3;
    end
  end
  
  // 输出级 - 现在连接到第四级流水线
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      rst_sync <= INIT_VAL;
    end else begin
      rst_sync <= flop_stage4;
    end
  end
  
  // 输出有效信号连接到第四级流水线的有效信号
  assign data_valid_out = valid_stage4;
  
endmodule