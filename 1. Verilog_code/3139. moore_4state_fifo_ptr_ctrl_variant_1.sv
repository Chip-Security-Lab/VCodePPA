//SystemVerilog
module moore_4state_fifo_ptr_ctrl #(parameter PTR_WIDTH = 4)(
  input  clk,
  input  rst,
  input  read_req,
  input  write_req,
  output reg [PTR_WIDTH-1:0] w_ptr,
  output reg [PTR_WIDTH-1:0] r_ptr,
  output reg full
);
  reg [1:0] state, next_state;
  localparam IDLE      = 2'b00,
             READ_OP   = 2'b01,
             WRITE_OP  = 2'b10,
             FULL_STATE= 2'b11;
             
  // 并行前缀加法器信号
  wire [1:0] p_w, g_w;  // 传播和生成信号 - 写指针
  wire [1:0] p_r, g_r;  // 传播和生成信号 - 读指针
  wire c_w_out, c_r_out; // 进位输出
  wire [PTR_WIDTH-1:0] w_ptr_next, r_ptr_next; // 下一个指针值

  // 计算传播和生成信号 - 写指针
  assign p_w[0] = w_ptr[0];
  assign g_w[0] = 1'b0;
  assign p_w[1] = w_ptr[1];
  assign g_w[1] = w_ptr[1] & w_ptr[0];
  
  // 计算传播和生成信号 - 读指针
  assign p_r[0] = r_ptr[0];
  assign g_r[0] = 1'b0;
  assign p_r[1] = r_ptr[1];
  assign g_r[1] = r_ptr[1] & r_ptr[0];
  
  // 计算进位
  assign c_w_out = g_w[1] | (p_w[1] & g_w[0]);
  assign c_r_out = g_r[1] | (p_r[1] & g_r[0]);
  
  // 计算新的指针值 - 低2位使用并行前缀加法器
  assign w_ptr_next[0] = w_ptr[0] ^ 1'b1;
  assign w_ptr_next[1] = w_ptr[1] ^ p_w[0];
  
  assign r_ptr_next[0] = r_ptr[0] ^ 1'b1;
  assign r_ptr_next[1] = r_ptr[1] ^ p_r[0];
  
  // 高位的进位处理 (如果PTR_WIDTH > 2)
  generate
    if (PTR_WIDTH > 2) begin
      assign w_ptr_next[PTR_WIDTH-1:2] = w_ptr[PTR_WIDTH-1:2] + c_w_out;
      assign r_ptr_next[PTR_WIDTH-1:2] = r_ptr[PTR_WIDTH-1:2] + c_r_out;
    end
  endgenerate

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state  <= IDLE;
      w_ptr  <= 0;
      r_ptr  <= 0;
    end else begin
      state <= next_state;
      if (state == WRITE_OP) w_ptr <= w_ptr_next;
      if (state == READ_OP)  r_ptr <= r_ptr_next;
    end
  end

  always @* begin
    full       = 1'b0;
    case (state)
      IDLE:       next_state = write_req ? WRITE_OP : (read_req ? READ_OP : IDLE);
      WRITE_OP:   next_state = (&w_ptr) ? FULL_STATE : IDLE; // 简化判断
      READ_OP:    next_state = IDLE;
      FULL_STATE: begin
                    full       = 1'b1;
                    next_state = read_req ? READ_OP : FULL_STATE;
                  end
    endcase
  end
endmodule