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

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state  <= IDLE;
      w_ptr  <= 0;
      r_ptr  <= 0;
    end else begin
      state <= next_state;
      if (state == WRITE_OP) w_ptr <= w_ptr + 1;
      if (state == READ_OP)  r_ptr <= r_ptr + 1;
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
