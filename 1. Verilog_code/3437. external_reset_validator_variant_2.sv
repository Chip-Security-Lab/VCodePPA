//SystemVerilog
/* IEEE 1364-2005 */
module external_reset_validator (
  input  wire clk,
  input  wire ext_reset,
  input  wire validation_en,
  output reg  valid_reset,
  output reg  invalid_reset
);
  // 同步器寄存器 - 第一级流水线
  reg [1:0] ext_reset_sync;
  
  // 流水线寄存器 - 第二级流水线
  reg reset_detected_stage1;
  reg validation_en_stage1;
  
  // 流水线控制信号
  reg valid_data_stage1;
  
  // 第一级流水线 - 同步和检测
  always @(posedge clk) begin
    // 两级同步器实现
    ext_reset_sync <= {ext_reset_sync[0], ext_reset};
    
    // 将检测信号和控制信号传递到下一级流水线
    reset_detected_stage1 <= ext_reset_sync[1];
    validation_en_stage1 <= validation_en;
    
    // 数据有效信号
    valid_data_stage1 <= 1'b1; // 这个简单设计中，数据总是有效的
  end
  
  // 第二级流水线 - 输出生成
  always @(posedge clk) begin
    if (valid_data_stage1) begin
      if (reset_detected_stage1) begin
        valid_reset   <= validation_en_stage1;
        invalid_reset <= ~validation_en_stage1;
      end else begin
        valid_reset   <= 1'b0;
        invalid_reset <= 1'b0;
      end
    end
  end
endmodule