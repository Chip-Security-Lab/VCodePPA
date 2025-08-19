//SystemVerilog
module can_overload_handler(
  input wire clk, rst_n,
  input wire can_rx, bit_timing,
  input wire frame_end, inter_frame_space,
  output reg overload_detected,
  output reg can_tx_overload
);
  reg [2:0] state;
  reg [3:0] bit_counter;
  
  // 4位带状进位加法器内部信号
  wire [3:0] p, g; // 传播进位和生成进位信号
  wire [4:0] c;    // 进位信号，包括初始进位c[0]
  wire [3:0] next_counter; // 下一个计数器值
  
  localparam IDLE = 0, DETECT = 1, FLAG = 2, DELIMITER = 3;
  
  // 生成传播进位和生成进位信号
  assign p[0] = bit_counter[0];
  assign p[1] = bit_counter[1];
  assign p[2] = bit_counter[2];
  assign p[3] = bit_counter[3];
  
  assign g[0] = 0;
  assign g[1] = bit_counter[0] & bit_counter[1];
  assign g[2] = bit_counter[1] & bit_counter[2];
  assign g[3] = bit_counter[2] & bit_counter[3];
  
  // 带状进位加法器进位逻辑
  assign c[0] = 1'b1; // 加1操作的初始进位
  assign c[1] = g[0] | (p[0] & c[0]);
  assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
  assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
  assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
  
  // 计算加1后的结果
  assign next_counter[0] = p[0] ^ c[0];
  assign next_counter[1] = p[1] ^ c[1];
  assign next_counter[2] = p[2] ^ c[2];
  assign next_counter[3] = p[3] ^ c[3];
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      overload_detected <= 0;
      can_tx_overload <= 0;
      bit_counter <= 0;
    end 
    else if (bit_timing && state == IDLE && frame_end) begin
      state <= DETECT;
    end
    else if (bit_timing && state == DETECT && inter_frame_space && !can_rx) begin
      state <= FLAG;
      overload_detected <= 1;
      bit_counter <= 0;
    end
    else if (bit_timing && state == FLAG) begin
      can_tx_overload <= 1;
      bit_counter <= next_counter; // 使用带状进位加法器
      if (bit_counter >= 5)
        state <= DELIMITER;
    end
    else if (bit_timing && state == DELIMITER) begin
      can_tx_overload <= 0;
      bit_counter <= next_counter; // 使用带状进位加法器
      if (bit_counter >= 7) begin
        state <= IDLE;
        overload_detected <= 0;
      end
    end
  end
endmodule