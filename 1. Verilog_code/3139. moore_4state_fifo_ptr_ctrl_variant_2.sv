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
  // 流水线阶段寄存器
  reg [1:0] state_stage1, next_state_stage1;
  reg [1:0] state_stage2;
  reg read_req_stage1, write_req_stage1;
  reg [PTR_WIDTH-1:0] w_ptr_stage1, r_ptr_stage1;
  reg write_op_valid_stage1, read_op_valid_stage1;
  reg full_stage1;
  
  // 流水线控制信号
  reg valid_stage1, valid_stage2;
  
  localparam IDLE      = 2'b00,
             READ_OP   = 2'b01,
             WRITE_OP  = 2'b10,
             FULL_STATE= 2'b11;

  // 第一级流水线：状态计算和控制逻辑
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage1 <= IDLE;
      read_req_stage1 <= 1'b0;
      write_req_stage1 <= 1'b0;
      w_ptr_stage1 <= 0;
      r_ptr_stage1 <= 0;
      valid_stage1 <= 1'b0;
    end else begin
      state_stage1 <= next_state_stage1;
      read_req_stage1 <= read_req;
      write_req_stage1 <= write_req;
      w_ptr_stage1 <= w_ptr;
      r_ptr_stage1 <= r_ptr;
      valid_stage1 <= 1'b1;
    end
  end
  
  // 第一级流水线：状态转换逻辑
  always @* begin
    full_stage1 = 1'b0;
    write_op_valid_stage1 = 1'b0;
    read_op_valid_stage1 = 1'b0;
    
    case (state_stage1)
      IDLE: begin
        next_state_stage1 = write_req_stage1 ? WRITE_OP : (read_req_stage1 ? READ_OP : IDLE);
        write_op_valid_stage1 = write_req_stage1;
        read_op_valid_stage1 = read_req_stage1 & ~write_req_stage1;
      end
      
      WRITE_OP: begin
        next_state_stage1 = (&w_ptr_stage1) ? FULL_STATE : IDLE;
        write_op_valid_stage1 = 1'b1;
      end
      
      READ_OP: begin
        next_state_stage1 = IDLE;
        read_op_valid_stage1 = 1'b1;
      end
      
      FULL_STATE: begin
        full_stage1 = 1'b1;
        next_state_stage1 = read_req_stage1 ? READ_OP : FULL_STATE;
        read_op_valid_stage1 = read_req_stage1;
      end
    endcase
  end
  
  // 第二级流水线：指针更新和输出寄存器
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage2 <= IDLE;
      w_ptr <= 0;
      r_ptr <= 0;
      full <= 1'b0;
      valid_stage2 <= 1'b0;
    end else begin
      state_stage2 <= state_stage1;
      valid_stage2 <= valid_stage1;
      
      // 只有在第一级流水线有效时才更新指针
      if (valid_stage1) begin
        if (write_op_valid_stage1) 
          w_ptr <= w_ptr_stage1 + 1;
        else
          w_ptr <= w_ptr_stage1;
          
        if (read_op_valid_stage1)
          r_ptr <= r_ptr_stage1 + 1;
        else
          r_ptr <= r_ptr_stage1;
          
        full <= full_stage1;
      end
    end
  end
endmodule