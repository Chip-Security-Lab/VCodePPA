//SystemVerilog
// 顶层模块
module sliding_window_parity(
  input clk, rst_n,
  input data_bit,
  input [2:0] window_size,
  output window_parity
);
  wire [7:0] shift_reg;
  
  // 实例化移位寄存器子模块
  shift_register shift_reg_inst (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_bit),
    .shift_out(shift_reg)
  );
  
  // 实例化奇偶校验计算子模块
  parity_calculator parity_calc_inst (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(shift_reg),
    .window_size(window_size),
    .parity_out(window_parity)
  );
  
endmodule

// 移位寄存器子模块
module shift_register(
  input clk, rst_n,
  input data_in,
  output reg [7:0] shift_out
);
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
      shift_out <= 8'h00;
    else 
      shift_out <= {shift_out[6:0], data_in};
  end
  
endmodule

// 奇偶校验计算子模块
module parity_calculator(
  input clk, rst_n,
  input [7:0] data_in,
  input [2:0] window_size,
  output reg parity_out
);
  
  // 优化奇偶校验计算逻辑
  reg [7:0] masked_data;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
      parity_out <= 1'b0;
    else begin
      // 使用case语句替代嵌套for循环，直接生成掩码
      case(window_size)
        3'd1: masked_data = {7'b0000000, data_in[0]};
        3'd2: masked_data = {6'b000000, data_in[1:0]};
        3'd3: masked_data = {5'b00000, data_in[2:0]};
        3'd4: masked_data = {4'b0000, data_in[3:0]};
        3'd5: masked_data = {3'b000, data_in[4:0]};
        3'd6: masked_data = {2'b00, data_in[5:0]};
        3'd7: masked_data = {1'b0, data_in[6:0]};
        3'd0, 3'd8: masked_data = data_in;
        default: masked_data = data_in;
      endcase
      
      // 计算奇偶校验
      parity_out <= ^masked_data;
    end
  end
  
endmodule