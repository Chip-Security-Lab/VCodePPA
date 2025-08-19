//SystemVerilog
module RD2(
  input clk, 
  input rst_n, 
  input en,
  input [7:0] data_in,
  output [7:0] data_out
);
  // 内部连线声明
  wire [7:0] next_value;
  reg [7:0] r_reg;
  
  // 组合逻辑部分
  RD2_comb comb_logic (
    .en(en),
    .data_in(data_in),
    .current_value(r_reg),
    .next_value(next_value)
  );
  
  // 时序逻辑部分
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
      r_reg <= 8'd0;
    else 
      r_reg <= next_value;
  end
  
  // 输出赋值
  assign data_out = r_reg;
endmodule

// 组合逻辑模块 - 使用显式多路复用器结构
module RD2_comb(
  input en,
  input [7:0] data_in,
  input [7:0] current_value,
  output [7:0] next_value
);
  // 使用显式多路复用器替代三元运算符
  reg [7:0] mux_out;
  
  always @(*) begin
    case(en)
      1'b1: mux_out = data_in;
      1'b0: mux_out = current_value;
      default: mux_out = current_value;
    endcase
  end
  
  assign next_value = mux_out;
endmodule