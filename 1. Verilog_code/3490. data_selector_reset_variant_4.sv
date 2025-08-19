//SystemVerilog
module data_selector_reset #(parameter WIDTH = 8)(
  input clk, rst_n,
  input [WIDTH-1:0] data_a, data_b, data_c, data_d,
  input [1:0] select,
  input valid_in,                // 输入有效信号
  output reg valid_out,          // 输出有效信号
  output reg [WIDTH-1:0] data_out
);
  
  // 第一级流水线信号
  reg [WIDTH-1:0] data_a_stage1, data_b_stage1, data_c_stage1, data_d_stage1;
  reg [1:0] select_stage1;
  reg valid_stage1;
  
  // 第二级流水线信号
  reg [WIDTH-1:0] selected_data_stage2;
  reg valid_stage2;
  
  // 第一级流水线 - 寄存输入数据
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_a_stage1 <= {WIDTH{1'b0}};
      data_b_stage1 <= {WIDTH{1'b0}};
      data_c_stage1 <= {WIDTH{1'b0}};
      data_d_stage1 <= {WIDTH{1'b0}};
      select_stage1 <= 2'b00;
      valid_stage1 <= 1'b0;
    end
    else begin
      data_a_stage1 <= data_a;
      data_b_stage1 <= data_b;
      data_c_stage1 <= data_c;
      data_d_stage1 <= data_d;
      select_stage1 <= select;
      valid_stage1 <= valid_in;
    end
  end
  
  // 第二级流水线 - 数据选择
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      selected_data_stage2 <= {WIDTH{1'b0}};
      valid_stage2 <= 1'b0;
    end
    else begin
      valid_stage2 <= valid_stage1;
      case (select_stage1)
        2'b00: selected_data_stage2 <= data_a_stage1;
        2'b01: selected_data_stage2 <= data_b_stage1;
        2'b10: selected_data_stage2 <= data_c_stage1;
        2'b11: selected_data_stage2 <= data_d_stage1;
        default: selected_data_stage2 <= {WIDTH{1'b0}}; // 安全处理
      endcase
    end
  end
  
  // 第三级流水线 - 最终输出
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_out <= {WIDTH{1'b0}};
      valid_out <= 1'b0;
    end
    else begin
      data_out <= selected_data_stage2;
      valid_out <= valid_stage2;
    end
  end
  
endmodule