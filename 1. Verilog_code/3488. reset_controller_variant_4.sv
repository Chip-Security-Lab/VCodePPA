//SystemVerilog
module reset_controller(
  input clk, master_rst_n, power_stable,
  output reg core_rst_n, periph_rst_n, io_rst_n
);
  // 状态编码定义
  localparam [1:0] RESET_STATE = 2'b00,
                   CORE_ACTIVE_STATE = 2'b01,
                   PERIPH_ACTIVE_STATE = 2'b10,
                   FULL_ACTIVE_STATE = 2'b11;
  
  reg [1:0] rst_state, next_state;
  
  // 状态转移逻辑 - 计算下一个状态
  always @(*) begin
    case (rst_state)
      RESET_STATE: 
        next_state = power_stable ? CORE_ACTIVE_STATE : RESET_STATE;
      CORE_ACTIVE_STATE: 
        next_state = power_stable ? PERIPH_ACTIVE_STATE : CORE_ACTIVE_STATE;
      PERIPH_ACTIVE_STATE: 
        next_state = power_stable ? FULL_ACTIVE_STATE : PERIPH_ACTIVE_STATE;
      FULL_ACTIVE_STATE: 
        next_state = FULL_ACTIVE_STATE;
      default: 
        next_state = RESET_STATE;
    endcase
  end
  
  // 状态寄存器更新逻辑
  always @(posedge clk or negedge master_rst_n) begin
    if (!master_rst_n)
      rst_state <= RESET_STATE;
    else
      rst_state <= next_state;
  end
  
  // 核心逻辑复位控制
  always @(posedge clk or negedge master_rst_n) begin
    if (!master_rst_n)
      core_rst_n <= 1'b0;
    else if (power_stable && (rst_state == RESET_STATE) && (next_state == CORE_ACTIVE_STATE))
      core_rst_n <= 1'b1;
  end
  
  // 外设逻辑复位控制
  always @(posedge clk or negedge master_rst_n) begin
    if (!master_rst_n)
      periph_rst_n <= 1'b0;
    else if (power_stable && (rst_state == CORE_ACTIVE_STATE) && (next_state == PERIPH_ACTIVE_STATE))
      periph_rst_n <= 1'b1;
  end
  
  // IO复位控制
  always @(posedge clk or negedge master_rst_n) begin
    if (!master_rst_n)
      io_rst_n <= 1'b0;
    else if (power_stable && (rst_state == PERIPH_ACTIVE_STATE) && (next_state == FULL_ACTIVE_STATE))
      io_rst_n <= 1'b1;
  end
  
endmodule