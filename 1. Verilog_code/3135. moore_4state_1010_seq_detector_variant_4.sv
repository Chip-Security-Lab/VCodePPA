//SystemVerilog
module moore_4state_1010_seq_detector(
  input  clk,
  input  rst,
  input  in,
  output found
);
  // 流水线寄存器定义
  reg [1:0] state_stage1;
  reg [1:0] state_stage2;
  reg [1:0] state_stage3;
  reg in_stage1;
  reg in_stage2;
  reg in_stage3;
  reg valid_stage1;
  reg valid_stage2;
  reg valid_stage3;
  
  // 内部信号
  wire [1:0] next_state;
  wire [1:0] state;
  
  // 状态寄存器实例化
  state_register state_reg_inst (
    .clk(clk),
    .rst(rst),
    .next_state(next_state),
    .current_state(state)
  );
  
  // 流水线第一级：输入采样
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage1 <= 2'b00;
      in_stage1 <= 1'b0;
      valid_stage1 <= 1'b0;
    end else begin
      state_stage1 <= state;
      in_stage1 <= in;
      valid_stage1 <= 1'b1;
    end
  end
  
  // 流水线第二级：状态计算
  next_state_logic nsl_inst (
    .current_state(state_stage1),
    .in(in_stage1),
    .next_state(next_state)
  );
  
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage2 <= 2'b00;
      in_stage2 <= 1'b0;
      valid_stage2 <= 1'b0;
    end else begin
      state_stage2 <= state_stage1;
      in_stage2 <= in_stage1;
      valid_stage2 <= valid_stage1;
    end
  end
  
  // 流水线第三级：输出计算
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage3 <= 2'b00;
      in_stage3 <= 1'b0;
      valid_stage3 <= 1'b0;
    end else begin
      state_stage3 <= state_stage2;
      in_stage3 <= in_stage2;
      valid_stage3 <= valid_stage2;
    end
  end
  
  output_logic ol_inst (
    .current_state(state_stage3),
    .in(in_stage3),
    .found(found)
  );
  
endmodule

module state_register (
  input clk,
  input rst,
  input [1:0] next_state,
  output reg [1:0] current_state
);
  localparam S0 = 2'b00;

  always @(posedge clk or posedge rst) begin
    if (rst)
      current_state <= S0;
    else
      current_state <= next_state;
  end
endmodule

module next_state_logic (
  input [1:0] current_state,
  input in,
  output reg [1:0] next_state
);
  localparam S0 = 2'b00,
             S1 = 2'b01,
             S2 = 2'b10,
             S3 = 2'b11;
             
  always @* begin
    case (current_state)
      S0: next_state = in ? S1 : S0;
      S1: next_state = in ? S1 : S2;
      S2: next_state = in ? S3 : S0;
      S3: next_state = in ? S1 : S2;
      default: next_state = S0;
    endcase
  end
endmodule

module output_logic (
  input [1:0] current_state,
  input in,
  output found
);
  localparam S3 = 2'b11;
  
  assign found = (current_state == S3 && in == 1'b0);
endmodule