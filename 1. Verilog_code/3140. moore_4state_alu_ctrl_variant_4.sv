//SystemVerilog
module moore_4state_alu_ctrl(
  input  clk,
  input  rst,
  input  start,
  input  [1:0] opcode,
  output reg [1:0] alu_op,
  output reg       done
);
  reg [1:0] state, next_state;
  localparam IDLE   = 2'b00,
             ADD_OP = 2'b01,
             MULT_OP = 2'b10,
             DONE_ST= 2'b11;

  // Karatsuba multiplier signals (2-bit)
  reg [1:0] a, b;          // Input operands
  wire [3:0] mult_result;  // Result of multiplication
  wire a0, a1, b0, b1;     // Individual bits
  wire z0, z1, z2;         // Karatsuba partial products
  
  // Split the inputs
  assign a0 = a[0];
  assign a1 = a[1];
  assign b0 = b[0];
  assign b1 = b[1];
  
  // Karatsuba algorithm for 2-bit multiplication
  assign z0 = a0 & b0;
  assign z2 = a1 & b1;
  assign z1 = ((a0 | a1) & (b0 | b1)) - z0 - z2;
  
  // Combine partial products
  assign mult_result = {z2, z2 | z1, z1 | z0, z0};

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state <= IDLE;
      a <= 2'b00;
      b <= 2'b00;
    end
    else begin
      state <= next_state;
      if (state == IDLE && start && opcode == 2'b10) begin
        a <= 2'b11;
        b <= 2'b10;
      end
    end
  end

  always @* begin
    alu_op = 2'b00;
    done   = 1'b0;
    next_state = state;

    if (state == IDLE) begin
      if (start) begin
        if (opcode == 2'b00) begin
          next_state = ADD_OP;
        end
        else if (opcode == 2'b10) begin
          next_state = MULT_OP;
        end
      end
    end
    else if (state == ADD_OP) begin
      alu_op = 2'b01;
      next_state = DONE_ST;
    end
    else if (state == MULT_OP) begin
      alu_op = 2'b10;
      next_state = DONE_ST;
    end
    else if (state == DONE_ST) begin
      done = 1'b1;
      next_state = IDLE;
    end
  end
endmodule