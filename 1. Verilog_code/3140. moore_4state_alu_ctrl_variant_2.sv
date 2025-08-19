//SystemVerilog
module moore_4state_alu_ctrl(
  input  clk,
  input  rst,
  input  start,
  input  [1:0] opcode,
  input  [1:0] a, b,     // 2位乘法输入
  output reg [1:0] alu_op,
  output reg       done,
  output [3:0] mul_result // 2位乘法结果输出
);
  reg [1:0] state, next_state;
  localparam IDLE   = 2'b00,
             ADD_OP = 2'b01,
             SH_OP  = 2'b10,
             DONE_ST= 2'b11;

  // Baugh-Wooley 2位乘法器实现
  wire [3:0] product;
  wire pp0, pp1, pp2, pp3;
  
  // 生成部分积
  assign pp0 = a[0] & b[0];
  assign pp1 = a[0] & b[1];
  assign pp2 = a[1] & b[0];
  assign pp3 = ~(a[1] & b[1]); // Baugh-Wooley算法中的负权重项
  
  // Baugh-Wooley乘法结果计算
  assign product[0] = pp0;
  assign product[1] = pp1 ^ pp2;
  assign product[2] = (pp1 & pp2) ^ pp3 ^ 1'b1; // 加上常数1
  assign product[3] = ~((pp1 & pp2) & pp3);
  
  // 将乘法结果连接到输出
  assign mul_result = product;

  always @(posedge clk or posedge rst) begin
    if (rst) state <= IDLE;
    else     state <= next_state;
  end

  always @* begin
    alu_op = 2'b00;
    done   = 1'b0;
    case (state)
      IDLE:   next_state = start ? (opcode == 2'b00 ? ADD_OP : SH_OP) : IDLE;
      ADD_OP: begin alu_op = 2'b01; next_state = DONE_ST; end
      SH_OP:  begin alu_op = 2'b10; next_state = DONE_ST; end
      DONE_ST:begin done   = 1'b1;  next_state = IDLE;    end
    endcase
  end
endmodule