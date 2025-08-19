//SystemVerilog
module moore_3state_mem_write_ctrl #(
  parameter ADDR_WIDTH = 4
)(
  input  wire clk,
  input  wire rst,
  input  wire start,
  output wire we,
  output wire [ADDR_WIDTH-1:0] addr
);
  
  // 内部连线
  wire [1:0] state;
  wire [1:0] next_state;
  wire addr_increment;
  
  // 实例化状态控制器子模块
  state_controller #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) state_ctrl_inst (
    .clk           (clk),
    .rst           (rst),
    .start         (start),
    .state         (state),
    .next_state    (next_state),
    .addr_increment(addr_increment)
  );
  
  // 实例化地址计数器子模块
  address_counter #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) addr_counter_inst (
    .clk           (clk),
    .rst           (rst),
    .addr_increment(addr_increment),
    .addr          (addr)
  );
  
  // 实例化输出生成器子模块
  output_generator output_gen_inst (
    .state(state),
    .we   (we)
  );
  
endmodule

// 状态控制器子模块：负责状态转换逻辑
module state_controller #(
  parameter ADDR_WIDTH = 4
)(
  input  wire clk,
  input  wire rst,
  input  wire start,
  output reg  [1:0] state,
  output wire [1:0] next_state,
  output wire addr_increment
);
  
  // 状态定义
  localparam IDLE     = 2'b00,
             SET_ADDR = 2'b01,
             WRITE    = 2'b10;
  
  // 状态转换逻辑
  reg [1:0] next_state_reg;
  assign next_state = next_state_reg;
  
  // 地址增量信号生成
  assign addr_increment = (state == SET_ADDR);
  
  // 状态更新时序逻辑
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state <= IDLE;
    end else begin
      state <= next_state;
    end
  end
  
  // 下一状态组合逻辑
  always @* begin
    case (state)
      IDLE:     next_state_reg = start ? SET_ADDR : IDLE;
      SET_ADDR: next_state_reg = WRITE;
      WRITE:    next_state_reg = IDLE;
      default:  next_state_reg = IDLE;
    endcase
  end
  
endmodule

// 地址计数器子模块：负责地址生成和递增
module address_counter #(
  parameter ADDR_WIDTH = 4
)(
  input  wire clk,
  input  wire rst,
  input  wire addr_increment,
  output reg  [ADDR_WIDTH-1:0] addr
);
  
  // 地址计数器逻辑
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      addr <= {ADDR_WIDTH{1'b0}};
    end else if (addr_increment) begin
      addr <= addr + 1'b1;
    end
  end
  
endmodule

// 输出生成器子模块：根据当前状态生成摩尔型输出
module output_generator (
  input  wire [1:0] state,
  output reg  we
);
  
  // 状态定义
  localparam IDLE     = 2'b00,
             SET_ADDR = 2'b01,
             WRITE    = 2'b10;
  
  // 摩尔型输出逻辑：根据当前状态生成输出
  always @* begin
    we = (state == WRITE);
  end
  
endmodule