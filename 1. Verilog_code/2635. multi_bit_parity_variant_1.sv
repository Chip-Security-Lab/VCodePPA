//SystemVerilog
//顶层模块
module multi_bit_parity(
  input clk,
  input rst_n,
  input [15:0] data_word,
  input req_in,
  output ack_in,
  output [1:0] parity_bits,
  output req_out,
  input ack_out
);
  wire [7:0] lower_byte, upper_byte;
  wire req_internal, ack_internal;
  reg [15:0] data_word_reg;
  reg [1:0] parity_bits_reg;
  
  // 数据缓存逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_word_reg <= 16'b0;
    end else if (req_in && ack_in) begin
      data_word_reg <= data_word;
    end
  end
  
  // 输出缓存逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      parity_bits_reg <= 2'b0;
    end else if (req_internal && ack_internal) begin
      parity_bits_reg <= parity_out_wire;
    end
  end
  
  // 握手逻辑
  assign ack_in = !req_internal || ack_internal;
  assign req_out = req_internal && ack_internal;
  assign req_internal = req_in;
  assign ack_internal = ack_out;
  
  wire [1:0] parity_out_wire;
  assign parity_bits = parity_bits_reg;

  // 实例化字节分离模块
  byte_splitter byte_split_inst (
    .data_in(data_word_reg),
    .req_in(req_internal),
    .ack_in(ack_internal),
    .lower_byte(lower_byte),
    .upper_byte(upper_byte),
    .req_out(req_internal),
    .ack_out(ack_internal)
  );

  // 实例化奇偶校验计算模块
  parity_calculator parity_calc_inst (
    .lower_byte(lower_byte),
    .upper_byte(upper_byte),
    .req_in(req_internal),
    .ack_in(ack_internal),
    .parity_out(parity_out_wire),
    .req_out(req_internal),
    .ack_out(ack_internal)
  );
endmodule

// 字节分离模块
module byte_splitter(
  input [15:0] data_in,
  input req_in,
  output ack_in,
  output [7:0] lower_byte,
  output [7:0] upper_byte,
  output req_out,
  input ack_out
);
  // 将输入数据分离为低字节和高字节
  assign lower_byte = data_in[7:0];
  assign upper_byte = data_in[15:8];
  
  // 直通握手信号
  assign req_out = req_in;
  assign ack_in = ack_out;
endmodule

// 奇偶校验计算模块
module parity_calculator(
  input [7:0] lower_byte,
  input [7:0] upper_byte,
  input req_in,
  output ack_in,
  output [1:0] parity_out,
  output req_out,
  input ack_out
);
  // 计算低字节和高字节的奇偶校验
  assign parity_out[0] = ^lower_byte; // 低字节的奇偶校验
  assign parity_out[1] = ^upper_byte; // 高字节的奇偶校验
  
  // 直通握手信号
  assign req_out = req_in;
  assign ack_in = ack_out;
endmodule