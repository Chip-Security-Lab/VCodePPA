//SystemVerilog
module binary_encoded_arbiter #(parameter WIDTH=4) (
  input clk, reset_n,
  input [WIDTH-1:0] req_i,
  output reg [$clog2(WIDTH)-1:0] sel_o,
  output reg valid_o
);
  integer i;
  
  // 流水线寄存器定义
  reg [WIDTH-1:0] req_stage1;
  reg valid_stage1;
  
  // 选择逻辑的流水线寄存器
  reg [$clog2(WIDTH)-1:0] sel_stage1;
  reg [$clog2(WIDTH)-1:0] sel_stage2;
  reg found_stage1;
  reg found_stage2;
  
  // 第一阶段：请求采样和有效信号生成
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      req_stage1 <= 0;
      valid_stage1 <= 0;
    end else begin
      req_stage1 <= req_i;
      valid_stage1 <= |req_i; // 计算有效信号
    end
  end
  
  // 第二阶段：优先级编码逻辑第一部分
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      found_stage1 <= 0;
      sel_stage1 <= 0;
    end else begin
      found_stage1 <= 0;
      sel_stage1 <= 0;
      
      // 将长组合逻辑拆分为两个部分
      for (i = 0; i < WIDTH/2; i = i + 1) begin
        if (req_stage1[i] && !found_stage1) begin
          sel_stage1 <= i[$clog2(WIDTH)-1:0];
          found_stage1 <= 1;
        end
      end
    end
  end
  
  // 第三阶段：优先级编码逻辑第二部分
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      found_stage2 <= 0;
      sel_stage2 <= 0;
    end else begin
      found_stage2 <= found_stage1;
      sel_stage2 <= sel_stage1;
      
      // 处理后半部分请求
      for (i = WIDTH/2; i < WIDTH; i = i + 1) begin
        if (req_stage1[i] && !found_stage1) begin
          sel_stage2 <= i[$clog2(WIDTH)-1:0];
          found_stage2 <= 1;
        end
      end
    end
  end
  
  // 最终阶段：输出选择信号和有效信号
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      sel_o <= 0;
      valid_o <= 0;
    end else begin
      sel_o <= sel_stage2;
      valid_o <= valid_stage1; // 有效信号与选择信号对齐
    end
  end
endmodule