//SystemVerilog
module uart_error_detect (
  input wire clk, rst_n,
  input wire serial_in,
  output reg [7:0] rx_data,
  output reg data_valid,
  output reg framing_error, parity_error, overrun_error
);
  // 定义状态编码
  localparam IDLE = 3'd0, START = 3'd1, DATA = 3'd2, PARITY = 3'd3, STOP = 3'd4;
  
  // 内部信号定义
  reg [2:0] state;
  reg [2:0] bit_count;
  reg [7:0] shift_reg;
  reg parity_bit;
  reg data_ready;
  reg prev_data_ready;
  wire [2:0] bit_count_next;
  
  // 位计数器加法器实例化
  bit_counter_module bit_counter_inst (
    .bit_count(bit_count),
    .bit_count_next(bit_count_next)
  );
  
  // UART状态控制器实例化
  uart_state_controller state_ctrl_inst (
    .clk(clk),
    .rst_n(rst_n),
    .serial_in(serial_in),
    .state(state),
    .bit_count(bit_count),
    .bit_count_next(bit_count_next),
    .shift_reg(shift_reg),
    .parity_bit(parity_bit),
    .data_ready(data_ready),
    .prev_data_ready(prev_data_ready),
    .data_valid(data_valid),
    .rx_data(rx_data),
    .framing_error(framing_error),
    .parity_error(parity_error),
    .overrun_error(overrun_error)
  );
  
endmodule

// UART状态控制器模块
module uart_state_controller (
  input wire clk, rst_n,
  input wire serial_in,
  output reg [2:0] state,
  output reg [2:0] bit_count,
  input wire [2:0] bit_count_next,
  output reg [7:0] shift_reg,
  output reg parity_bit,
  output reg data_ready,
  output reg prev_data_ready,
  output reg data_valid,
  output reg [7:0] rx_data,
  output reg framing_error, parity_error, overrun_error
);
  // 状态编码定义
  localparam IDLE = 3'd0, START = 3'd1, DATA = 3'd2, PARITY = 3'd3, STOP = 3'd4;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      bit_count <= 0;
      shift_reg <= 0;
      parity_bit <= 0;
      framing_error <= 0;
      parity_error <= 0;
      overrun_error <= 0;
      data_valid <= 0;
      data_ready <= 0;
      prev_data_ready <= 0;
    end else begin
      prev_data_ready <= data_ready;
      
      case (state)
        IDLE: begin
          if (serial_in == 1'b0) begin
            state <= START;
          end
          if (data_ready && !prev_data_ready) begin
            rx_data <= shift_reg;
            data_valid <= 1;
          end else begin
            data_valid <= 0;
          end
        end
        START: begin
          state <= DATA;
          bit_count <= 0;
          shift_reg <= 0;
          parity_bit <= 0;
        end
        DATA: begin
          shift_reg <= {serial_in, shift_reg[7:1]};
          parity_bit <= parity_bit ^ serial_in; // Calculate odd parity
          if (bit_count == 7) begin
            state <= PARITY;
          end else begin
            bit_count <= bit_count_next; // 使用加法器
          end
        end
        PARITY: begin
          state <= STOP;
          parity_error <= (parity_bit == serial_in); // Odd parity check
        end
        STOP: begin
          state <= IDLE;
          framing_error <= (serial_in == 0); // STOP bit should be 1
          overrun_error <= data_ready && !prev_data_ready && !data_valid;
          data_ready <= 1;
        end
      endcase
    end
  end
endmodule

// 位计数器模块
module bit_counter_module (
  input wire [2:0] bit_count,
  output wire [2:0] bit_count_next
);
  // 实例化Han-Carlson加法器
  han_carlson_adder #(
    .WIDTH(3)
  ) bit_counter_adder (
    .a(bit_count),
    .b(3'b001),
    .sum(bit_count_next)
  );
endmodule

// Han-Carlson 并行前缀加法器模块
module han_carlson_adder #(
  parameter WIDTH = 3
)(
  input wire [WIDTH-1:0] a,
  input wire [WIDTH-1:0] b,
  output wire [WIDTH-1:0] sum
);
  // 优化版前缀加法器实现
  // 分解为生成/传播计算和进位生成两个阶段
  wire [WIDTH-1:0] p, g;
  wire [WIDTH:0] carry;
  
  // 第一阶段：计算生成和传播逻辑
  adder_pg_logic #(
    .WIDTH(WIDTH)
  ) pg_logic_inst (
    .a(a),
    .b(b),
    .p(p),
    .g(g)
  );
  
  // 第二阶段：并行前缀进位计算
  adder_prefix_network #(
    .WIDTH(WIDTH)
  ) prefix_network_inst (
    .p(p),
    .g(g),
    .carry(carry)
  );
  
  // 最终和计算
  assign sum = p ^ carry[WIDTH-1:0];
endmodule

// 加法器预处理模块：计算生成和传播信号
module adder_pg_logic #(
  parameter WIDTH = 3
)(
  input wire [WIDTH-1:0] a,
  input wire [WIDTH-1:0] b,
  output wire [WIDTH-1:0] p,
  output wire [WIDTH-1:0] g
);
  // 传播信号
  assign p = a ^ b;
  // 生成信号
  assign g = a & b;
endmodule

// 加法器前缀网络模块：处理进位传播
module adder_prefix_network #(
  parameter WIDTH = 3
)(
  input wire [WIDTH-1:0] p,
  input wire [WIDTH-1:0] g,
  output wire [WIDTH:0] carry
);
  wire [WIDTH-1:0] p_prefix, g_prefix;
  
  // 初始进位为0
  assign carry[0] = 1'b0;
  
  // Han-Carlson算法中的预处理
  // 偶数位置的初始化
  generate
    genvar i;
    for (i = 0; i < WIDTH; i = i + 2) begin : even_init
      assign p_prefix[i] = p[i];
      assign g_prefix[i] = g[i];
    end
  endgenerate
  
  // 奇数位置处理
  generate
    genvar j;
    for (j = 1; j < WIDTH; j = j + 2) begin : odd_process
      assign p_prefix[j] = p[j] & p[j-1];
      assign g_prefix[j] = g[j] | (p[j] & g[j-1]);
    end
  endgenerate
  
  // 组合生成和传播到最终进位
  generate
    genvar k;
    for (k = 0; k < WIDTH; k = k + 1) begin : carry_gen
      assign carry[k+1] = g_prefix[k] | (p_prefix[k] & carry[k]);
    end
  endgenerate
endmodule