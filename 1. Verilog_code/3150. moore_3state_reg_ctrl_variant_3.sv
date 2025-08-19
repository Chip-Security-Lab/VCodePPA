//SystemVerilog
// 顶层模块
module moore_3state_reg_ctrl #(
  parameter WIDTH = 8
)(
  input  wire clk,
  input  wire rst,
  input  wire start,
  input  wire [WIDTH-1:0] din,
  output wire [WIDTH-1:0] dout
);
  // 状态编码
  localparam [1:0] HOLD  = 2'b00,
                   LOAD  = 2'b01,
                   CLEAR = 2'b10;
  
  // 内部连线
  wire [1:0] current_state;
  wire load_enable, clear_enable;
  
  // 子模块实例化
  state_controller u_state_controller (
    .clk          (clk),
    .rst          (rst),
    .start        (start),
    .current_state(current_state),
    .load_enable  (load_enable),
    .clear_enable (clear_enable)
  );
  
  datapath #(
    .WIDTH(WIDTH)
  ) u_datapath (
    .clk         (clk),
    .rst         (rst),
    .din         (din),
    .load_enable (load_enable),
    .clear_enable(clear_enable),
    .dout        (dout)
  );

endmodule

// 状态控制器子模块
module state_controller (
  input  wire clk,
  input  wire rst,
  input  wire start,
  output reg [1:0] current_state,
  output wire load_enable,
  output wire clear_enable
);
  // 状态编码
  localparam [1:0] HOLD  = 2'b00,
                   LOAD  = 2'b01,
                   CLEAR = 2'b10;
  
  reg [1:0] next_state;
  
  // 状态转移逻辑
  always @* begin
    case (current_state)
      HOLD:  next_state = start ? LOAD : HOLD;
      LOAD:  next_state = CLEAR;
      CLEAR: next_state = HOLD;
      default: next_state = HOLD;
    endcase
  end
  
  // 状态寄存器
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      current_state <= HOLD;
    end else begin
      current_state <= next_state;
    end
  end
  
  // 控制信号生成
  assign load_enable = (current_state == LOAD);
  assign clear_enable = (current_state == CLEAR);
  
endmodule

// 数据路径子模块
module datapath #(
  parameter WIDTH = 8
)(
  input  wire clk,
  input  wire rst,
  input  wire [WIDTH-1:0] din,
  input  wire load_enable,
  input  wire clear_enable,
  output reg  [WIDTH-1:0] dout
);

  // 数据处理逻辑
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      dout <= {WIDTH{1'b0}};
    end else if (load_enable) begin
      dout <= din;
    end else if (clear_enable) begin
      dout <= {WIDTH{1'b0}};
    end
  end
  
endmodule