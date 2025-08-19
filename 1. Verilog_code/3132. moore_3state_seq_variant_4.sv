//SystemVerilog
module moore_3state_seq #(parameter WIDTH = 4)(
  input  clk,
  input  rst,
  output reg [WIDTH-1:0] seq_out
);
  // 状态定义
  localparam S0 = 2'b00,
             S1 = 2'b01,
             S2 = 2'b10;
             
  // 流水线寄存器和控制信号
  reg [1:0] state_stage1, next_state_stage1;
  reg [1:0] state_stage2;
  reg [1:0] state_stage3;
  reg [WIDTH-1:0] seq_out_stage1;
  reg [WIDTH-1:0] seq_out_stage2;

  // 第一级流水线 - 状态转换
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage1 <= S0;
    end
    else begin
      state_stage1 <= next_state_stage1;
    end
  end

  // 状态转换逻辑
  always @* begin
    case (state_stage1)
      S0: next_state_stage1 = S1;
      S1: next_state_stage1 = S2;
      S2: next_state_stage1 = S0;
      default: next_state_stage1 = S0;
    endcase
  end

  // 第二级流水线 - 传递状态
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage2 <= S0;
    end
    else begin
      state_stage2 <= state_stage1;
    end
  end
  
  // 第二级流水线 - 输出计算的第一部分
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      seq_out_stage1 <= {WIDTH{1'b0}};
    end
    else begin
      case (state_stage2)
        S0: seq_out_stage1 <= {WIDTH{1'b0}};
        S1: seq_out_stage1 <= {WIDTH{1'b1}};
        S2: seq_out_stage1 <= {{(WIDTH/2){2'b10}} , {(WIDTH%2){1'b0}}};
        default: seq_out_stage1 <= {WIDTH{1'b0}};
      endcase
    end
  end

  // 第三级流水线 - 传递状态
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage3 <= S0;
    end
    else begin
      state_stage3 <= state_stage2;
    end
  end
  
  // 第三级流水线 - 输出计算的第二部分和注册
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      seq_out_stage2 <= {WIDTH{1'b0}};
    end
    else begin
      seq_out_stage2 <= seq_out_stage1;
    end
  end
  
  // 最终输出赋值
  always @* begin
    seq_out = seq_out_stage2;
  end
endmodule