//SystemVerilog
//IEEE 1364-2005 Verilog
module data_selector_reset #(parameter WIDTH = 8)(
  input wire clk, rst_n,
  input wire [WIDTH-1:0] data_a, data_b, data_c, data_d,
  input wire [1:0] select,
  output reg [WIDTH-1:0] data_out
);
  // 重定时：将寄存器前移到组合逻辑之前，分别寄存输入数据
  reg [WIDTH-1:0] reg_data_a, reg_data_b, reg_data_c, reg_data_d;
  reg [1:0] reg_select;
  
  // 输入信号寄存
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      reg_data_a <= {WIDTH{1'b0}};
      reg_data_b <= {WIDTH{1'b0}};
      reg_data_c <= {WIDTH{1'b0}};
      reg_data_d <= {WIDTH{1'b0}};
      reg_select <= 2'b00;
    end
    else begin
      reg_data_a <= data_a;
      reg_data_b <= data_b;
      reg_data_c <= data_c;
      reg_data_d <= data_d;
      reg_select <= select;
    end
  end
  
  // 组合逻辑直接连接到输出，无需额外寄存
  always @(*) begin
    data_out = ({WIDTH{~reg_select[1] & ~reg_select[0]}} & reg_data_a) |
               ({WIDTH{~reg_select[1] &  reg_select[0]}} & reg_data_b) |
               ({WIDTH{ reg_select[1] & ~reg_select[0]}} & reg_data_c) |
               ({WIDTH{ reg_select[1] &  reg_select[0]}} & reg_data_d);
  end
endmodule