//SystemVerilog
module moore_4state_ring #(parameter WIDTH = 4)(
  input  clk,
  input  rst,
  output reg [WIDTH-1:0] ring_out
);
  // 流水线状态寄存器
  reg [1:0] state_stage1, next_state_stage1;
  reg [1:0] state_stage2;
  reg valid_stage1, valid_stage2;
  
  // 流水线输出寄存器
  reg [WIDTH-1:0] ring_out_stage1, ring_out_stage2;
  
  localparam S0 = 2'b00,
             S1 = 2'b01,
             S2 = 2'b10,
             S3 = 2'b11;

  // 第一级流水线 - 状态转移逻辑
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage1 <= S0;
      valid_stage1 <= 1'b0;
    end
    else begin
      state_stage1 <= next_state_stage1;
      valid_stage1 <= 1'b1;
    end
  end

  // 状态转移组合逻辑
  always @* begin
    case (state_stage1)
      S0: next_state_stage1 = S1;
      S1: next_state_stage1 = S2;
      S2: next_state_stage1 = S3;
      S3: next_state_stage1 = S0;
      default: next_state_stage1 = S0;
    endcase
  end

  // 第一级流水线输出逻辑
  always @* begin
    ring_out_stage1 = (state_stage1 == S0) ? 4'b0001 :
                      (state_stage1 == S1) ? 4'b0010 :
                      (state_stage1 == S2) ? 4'b0100 :
                      (state_stage1 == S3) ? 4'b1000 : 4'b0000;
  end

  // 第二级流水线 - 输出寄存器
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage2 <= S0;
      ring_out_stage2 <= {WIDTH{1'b0}};
      valid_stage2 <= 1'b0;
    end
    else begin
      state_stage2 <= state_stage1;
      ring_out_stage2 <= ring_out_stage1;
      valid_stage2 <= valid_stage1;
    end
  end

  // 最终输出逻辑
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      ring_out <= {WIDTH{1'b0}};
    end
    else if (valid_stage2) begin
      ring_out <= ring_out_stage2;
    end
  end
endmodule