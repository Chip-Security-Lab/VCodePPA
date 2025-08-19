//SystemVerilog
// SystemVerilog
module uart_baud_gen #(parameter CLK_FREQ = 50_000_000) (
  input wire sys_clk, rst_n,
  input wire [15:0] baud_val, // Desired baud rate
  input wire [7:0] tx_data,
  input wire tx_start,
  output wire tx_out,
  output wire tx_done
);
  // 内部连线
  wire [15:0] bit_duration;
  wire [1:0] next_state;
  wire [15:0] next_baud_counter;
  wire [2:0] next_bit_idx;
  wire [7:0] next_tx_reg;
  wire next_tx_out, next_tx_done;
  
  // 状态寄存器
  reg [1:0] state;
  reg [15:0] baud_counter;
  reg [2:0] bit_idx;
  reg [7:0] tx_reg;
  reg tx_out_reg, tx_done_reg;
  
  // 输出赋值
  assign tx_out = tx_out_reg;
  assign tx_done = tx_done_reg;

  // 实例化波特率计算模块
  baud_calculator #(.CLK_FREQ(CLK_FREQ)) baud_calc (
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    .baud_val(baud_val),
    .bit_duration(bit_duration)
  );
  
  // 实例化组合逻辑控制模块
  uart_combo_logic uart_combo (
    .state(state),
    .baud_counter(baud_counter),
    .bit_idx(bit_idx),
    .tx_reg(tx_reg),
    .tx_out(tx_out_reg),
    .tx_done(tx_done_reg),
    .tx_start(tx_start),
    .tx_data(tx_data),
    .bit_duration(bit_duration),
    .next_state(next_state),
    .next_baud_counter(next_baud_counter),
    .next_bit_idx(next_bit_idx),
    .next_tx_reg(next_tx_reg),
    .next_tx_out(next_tx_out),
    .next_tx_done(next_tx_done)
  );
  
  // 时序逻辑 - 状态寄存器更新
  always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= 2'b00; // IDLE
      baud_counter <= 0;
      bit_idx <= 0;
      tx_reg <= 0;
      tx_out_reg <= 1'b1;
      tx_done_reg <= 1'b0;
    end else begin
      state <= next_state;
      baud_counter <= next_baud_counter;
      bit_idx <= next_bit_idx;
      tx_reg <= next_tx_reg;
      tx_out_reg <= next_tx_out;
      tx_done_reg <= next_tx_done;
    end
  end
endmodule

// 波特率计算模块 - 纯组合逻辑
module baud_calculator #(parameter CLK_FREQ = 50_000_000) (
  input wire sys_clk, rst_n,
  input wire [15:0] baud_val,
  output reg [15:0] bit_duration
);
  // 计算波特率持续时间 - 时序逻辑
  always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
      bit_duration <= 0;
    end else begin
      bit_duration <= CLK_FREQ / baud_val;
    end
  end
endmodule

// 组合逻辑控制模块
module uart_combo_logic (
  // 输入
  input wire [1:0] state,
  input wire [15:0] baud_counter,
  input wire [2:0] bit_idx,
  input wire [7:0] tx_reg,
  input wire tx_out, tx_done,
  input wire tx_start,
  input wire [7:0] tx_data,
  input wire [15:0] bit_duration,
  
  // 输出
  output reg [1:0] next_state,
  output reg [15:0] next_baud_counter,
  output reg [2:0] next_bit_idx,
  output reg [7:0] next_tx_reg,
  output reg next_tx_out, next_tx_done
);
  // 状态定义
  localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
  
  // 纯组合逻辑 - 状态转换和输出计算
  always @(*) begin
    // 默认保持当前值
    next_state = state;
    next_baud_counter = baud_counter;
    next_bit_idx = bit_idx;
    next_tx_reg = tx_reg;
    next_tx_out = tx_out;
    next_tx_done = tx_done;
    
    case (state)
      IDLE: begin
        next_tx_out = 1'b1;
        next_tx_done = 1'b0;
        if (tx_start) begin
          next_state = START;
          next_tx_reg = tx_data;
          next_baud_counter = 0;
        end
      end
      
      START: begin
        next_tx_out = 1'b0;
        next_baud_counter = baud_counter + 1;
        if (baud_counter >= bit_duration-1) begin
          next_baud_counter = 0;
          next_state = DATA;
          next_bit_idx = 0;
        end
      end
      
      DATA: begin
        next_tx_out = tx_reg[bit_idx];
        next_baud_counter = baud_counter + 1;
        if (baud_counter >= bit_duration-1) begin
          next_baud_counter = 0;
          if (bit_idx == 7) 
            next_state = STOP;
          else 
            next_bit_idx = bit_idx + 1;
        end
      end
      
      STOP: begin
        next_tx_out = 1'b1;
        next_baud_counter = baud_counter + 1;
        if (baud_counter >= bit_duration-1) begin
          next_state = IDLE;
          next_tx_done = 1'b1;
        end
      end
    endcase
  end
endmodule