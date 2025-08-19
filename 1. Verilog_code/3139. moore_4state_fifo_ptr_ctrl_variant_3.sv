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

  // Manchester carry chain adder signals
  wire [PTR_WIDTH-1:0] w_ptr_next;
  wire [PTR_WIDTH-1:0] r_ptr_next;
  wire [PTR_WIDTH:0] w_carry;
  wire [PTR_WIDTH:0] r_carry;

  // Manchester carry chain for write pointer
  assign w_carry[0] = 1'b0;
  genvar i;
  generate
    for(i=0; i<PTR_WIDTH; i=i+1) begin : w_ptr_chain
      assign w_ptr_next[i] = w_ptr[i] ^ w_carry[i];
      assign w_carry[i+1] = (w_ptr[i] & w_carry[i]) | (w_carry[i]);
    end
  endgenerate

  // Manchester carry chain for read pointer
  assign r_carry[0] = 1'b0;
  generate
    for(i=0; i<PTR_WIDTH; i=i+1) begin : r_ptr_chain
      assign r_ptr_next[i] = r_ptr[i] ^ r_carry[i];
      assign r_carry[i+1] = (r_ptr[i] & r_carry[i]) | (r_carry[i]);
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
    full = (state == FULL_STATE);
    case (state)
      IDLE:       next_state = write_req ? WRITE_OP : (read_req ? READ_OP : IDLE);
      WRITE_OP:   next_state = (&w_ptr) ? FULL_STATE : IDLE;
      READ_OP:    next_state = IDLE;
      FULL_STATE: next_state = read_req ? READ_OP : FULL_STATE;
    endcase
  end

endmodule