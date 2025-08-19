//SystemVerilog
//IEEE 1364-2005 Verilog
module bidirectional_counter_reset #(parameter WIDTH = 8)(
  input clk,
  input reset,
  input up_down,
  input load,
  input enable,
  input [WIDTH-1:0] data_in,
  input data_valid_in,
  output [WIDTH-1:0] count,
  output count_valid_out,
  output reg ready_for_input
);
  // 流水线阶段寄存器和控制信号
  reg [WIDTH-1:0] stage1_count, stage2_count;
  reg [WIDTH-1:0] stage1_data_in;
  reg stage1_up_down, stage1_load, stage1_enable;
  reg stage1_valid, stage2_valid;
  
  // 先行借位减法器信号
  wire [WIDTH-1:0] sub_result;
  wire [WIDTH:0] borrow;
  
  // 第一级流水线 - 输入寄存和控制信号处理
  always @(posedge clk) begin
    if (reset) begin
      stage1_data_in <= {WIDTH{1'b0}};
      stage1_up_down <= 1'b0;
      stage1_load <= 1'b0;
      stage1_enable <= 1'b0;
      stage1_valid <= 1'b0;
      ready_for_input <= 1'b1;
    end
    else if (data_valid_in && ready_for_input) begin
      stage1_data_in <= data_in;
      stage1_up_down <= up_down;
      stage1_load <= load;
      stage1_enable <= enable;
      stage1_valid <= 1'b1;
      ready_for_input <= 1'b0;
    end
    else begin
      stage1_valid <= 1'b0;
      ready_for_input <= 1'b1;
    end
  end
  
  // 先行借位减法器实现
  assign borrow[0] = 1'b0;
  
  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin : gen_borrow
      assign borrow[i+1] = (~stage1_count[i] & borrow[i]) | (~stage1_count[i] & 1'b1) | (borrow[i] & 1'b1);
      assign sub_result[i] = stage1_count[i] ^ 1'b1 ^ borrow[i];
    end
  endgenerate
  
  // 第二级流水线 - 计算逻辑
  always @(posedge clk) begin
    if (reset) begin
      stage1_count <= {WIDTH{1'b0}};
      stage2_valid <= 1'b0;
    end
    else if (stage1_valid) begin
      if (stage1_load)
        stage1_count <= stage1_data_in;
      else if (stage1_enable) begin
        if (stage1_up_down)
          stage1_count <= stage1_count + 1'b1;
        else
          stage1_count <= sub_result;
      end
      stage2_valid <= 1'b1;
    end
    else begin
      stage2_valid <= 1'b0;
    end
  end
  
  // 第三级流水线 - 输出寄存
  always @(posedge clk) begin
    if (reset) begin
      stage2_count <= {WIDTH{1'b0}};
    end
    else if (stage2_valid) begin
      stage2_count <= stage1_count;
    end
  end
  
  // 输出分配
  assign count = stage2_count;
  assign count_valid_out = stage2_valid;
  
endmodule