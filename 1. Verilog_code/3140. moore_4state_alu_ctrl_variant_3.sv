//SystemVerilog
module moore_4state_alu_ctrl(
  input  clk,
  input  rst,
  input  start,
  input  [1:0] opcode,
  input  [1:0] a,
  input  [1:0] b,
  output reg [1:0] alu_op,
  output reg       done,
  output reg [3:0] result
);
  reg [1:0] state, next_state;
  localparam IDLE    = 2'b00,
             ADD_OP  = 2'b01,
             MULT_OP = 2'b10,
             DONE_ST = 2'b11;

  // Baugh-Wooley乘法器内部信号
  wire [3:0] mult_result;
  wire p00, p01, p10, p11;
  wire sign_term1, sign_term2;
  
  // Baugh-Wooley 2位乘法器实现
  assign p00 = a[0] & b[0];
  assign p01 = a[0] & b[1];
  assign p10 = a[1] & b[0];
  assign sign_term1 = ~(a[1] & b[1]);  // 负权重项1
  
  // Baugh-Wooley部分积计算
  assign mult_result[0] = p00;
  assign mult_result[1] = p01 ^ p10;
  assign mult_result[2] = (p01 & p10) ^ sign_term1;
  assign mult_result[3] = ~(p01 & p10 & sign_term1);  // 最高位符号扩展

  always @(posedge clk or posedge rst) begin
    if (rst) state <= IDLE;
    else     state <= next_state;
  end

  always @* begin
    alu_op = 2'b00;
    done   = 1'b0;
    result = 4'b0000;
    case (state)
      IDLE:   next_state = start ? (opcode == 2'b00 ? ADD_OP : MULT_OP) : IDLE;
      ADD_OP: begin 
        alu_op = 2'b01; 
        result = {2'b00, a + b};  // 2位加法运算
        next_state = DONE_ST; 
      end
      MULT_OP: begin 
        alu_op = 2'b10; 
        result = mult_result;     // Baugh-Wooley乘法结果
        next_state = DONE_ST; 
      end
      DONE_ST: begin 
        done = 1'b1;  
        next_state = IDLE;    
      end
    endcase
  end
endmodule