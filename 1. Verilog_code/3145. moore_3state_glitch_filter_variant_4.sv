//SystemVerilog
// 顶层模块 - 毛刺滤波器（增加流水线深度）
module moore_3state_glitch_filter (
  input  clk,
  input  rst,
  input  in,
  output out
);
  // 内部连线和寄存器
  wire [1:0] state_stage1;
  wire [1:0] next_state_stage1;
  reg  in_stage1, in_stage2;
  reg  [1:0] state_stage2;
  wire [1:0] next_state_stage2;
  reg  [1:0] state_stage3;
  
  // 输入寄存
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      in_stage1 <= 1'b0;
      in_stage2 <= 1'b0;
    end else begin
      in_stage1 <= in;
      in_stage2 <= in_stage1;
    end
  end
  
  // 状态寄存（第一级流水线）
  state_register state_reg_stage1 (
    .clk(clk),
    .rst(rst),
    .next_state(next_state_stage1),
    .state(state_stage1)
  );
  
  // 状态转移计算第一阶段（低复杂度部分）
  next_state_logic_stage1 next_state_stage1_inst (
    .state(state_stage1),
    .in(in_stage1),
    .next_state(next_state_stage1)
  );
  
  // 状态传递（第二级流水线）
  always @(posedge clk or posedge rst) begin
    if (rst)
      state_stage2 <= 2'b00;
    else
      state_stage2 <= state_stage1;
  end
  
  // 状态转移计算第二阶段（高复杂度部分）
  next_state_logic_stage2 next_state_stage2_inst (
    .state(state_stage2),
    .in(in_stage2),
    .next_state(next_state_stage2)
  );
  
  // 状态传递（第三级流水线）
  always @(posedge clk or posedge rst) begin
    if (rst)
      state_stage3 <= 2'b00;
    else
      state_stage3 <= state_stage2;
  end
  
  // 输出逻辑（级联到第三级流水线）
  output_logic output_inst (
    .state(state_stage3),
    .out(out)
  );
endmodule

// 子模块1: 状态寄存器 - 处理时序逻辑
module state_register (
  input  clk,
  input  rst,
  input  [1:0] next_state,
  output reg [1:0] state
);
  // 状态编码
  localparam STABLE0 = 2'b00;
  
  always @(posedge clk or posedge rst) begin
    if (rst) 
      state <= STABLE0;
    else     
      state <= next_state;
  end
endmodule

// 子模块2: 下一状态逻辑第一阶段 - 预处理状态信息
module next_state_logic_stage1 (
  input  [1:0] state,
  input  in,
  output reg [1:0] next_state
);
  // 状态编码
  localparam STABLE0 = 2'b00,
             TRANS   = 2'b01,
             STABLE1 = 2'b10;
  
  // 第一阶段状态解码和基本状态预处理
  always @* begin
    case (state)
      STABLE0: next_state = in ? TRANS : STABLE0;
      TRANS:   next_state = in ? STABLE1 : STABLE0;
      STABLE1: next_state = in ? STABLE1 : TRANS;
      default: next_state = STABLE0;
    endcase
  end
endmodule

// 子模块3: 下一状态逻辑第二阶段 - 最终状态确定
module next_state_logic_stage2 (
  input  [1:0] state,
  input  in,
  output reg [1:0] next_state
);
  // 状态编码
  localparam STABLE0 = 2'b00,
             TRANS   = 2'b01,
             STABLE1 = 2'b10;
             
  // 第二阶段最终状态确定
  always @* begin
    case (state)
      STABLE0: next_state = in ? TRANS : STABLE0;
      TRANS:   next_state = in ? STABLE1 : STABLE0;
      STABLE1: next_state = in ? STABLE1 : TRANS;
      default: next_state = STABLE0;
    endcase
  end
endmodule

// 子模块4: 输出逻辑 - 处理输出生成
module output_logic (
  input  [1:0] state,
  output reg out
);
  // 状态编码
  localparam STABLE1 = 2'b10;
  
  always @* begin
    out = (state == STABLE1);
  end
endmodule