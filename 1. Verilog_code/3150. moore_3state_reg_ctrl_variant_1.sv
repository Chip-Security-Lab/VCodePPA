//SystemVerilog
module moore_3state_reg_ctrl #(parameter WIDTH = 8)(
  input  clk,
  input  rst,
  input  start,
  input  [WIDTH-1:0] din,
  output reg [WIDTH-1:0] dout
);
  reg [1:0] state, next_state;
  localparam HOLD  = 2'b00,
             LOAD  = 2'b01,
             CLEAR = 2'b10;
             
  // Lookup table for 2-bit subtraction
  reg [1:0] sub_lut [0:15];
  
  // Initialize lookup table
  initial begin
    // Format: sub_lut[{a1,a0,b1,b0}] = a-b
    sub_lut[4'b0000] = 2'b00; // 0-0=0
    sub_lut[4'b0001] = 2'b11; // 0-1=-1
    sub_lut[4'b0010] = 2'b10; // 0-2=-2
    sub_lut[4'b0011] = 2'b01; // 0-3=-3
    sub_lut[4'b0100] = 2'b01; // 1-0=1
    sub_lut[4'b0101] = 2'b00; // 1-1=0
    sub_lut[4'b0110] = 2'b11; // 1-2=-1
    sub_lut[4'b0111] = 2'b10; // 1-3=-2
    sub_lut[4'b1000] = 2'b10; // 2-0=2
    sub_lut[4'b1001] = 2'b01; // 2-1=1
    sub_lut[4'b1010] = 2'b00; // 2-2=0
    sub_lut[4'b1011] = 2'b11; // 2-3=-1
    sub_lut[4'b1100] = 2'b11; // 3-0=3
    sub_lut[4'b1101] = 2'b10; // 3-1=2
    sub_lut[4'b1110] = 2'b01; // 3-2=1
    sub_lut[4'b1111] = 2'b00; // 3-3=0
  end
  
  // Registers for 2-bit subtraction
  reg [1:0] a_reg, b_reg;
  reg [1:0] sub_result;
  integer i;
  
  // Process 2-bit chunks of the input
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state <= HOLD;
      dout  <= 0;
      a_reg <= 0;
      b_reg <= 0;
      sub_result <= 0;
    end else begin
      state <= next_state;
      case (state)
        LOAD: begin
          // Process 2-bit chunks using lookup table
          // Initialize loop variable before while loop
          i = 0;
          while (i < WIDTH) begin
            a_reg = din[i+:2];
            b_reg = 2'b00; // Subtracting 0 in this case
            sub_result = sub_lut[{a_reg, b_reg}];
            dout[i+:2] = sub_result;
            // Iteration step at the end of loop body
            i = i + 2;
          end
        end
        CLEAR: dout <= 0;
      endcase
    end
  end

  always @* begin
    case (state)
      HOLD:  next_state = start ? LOAD : HOLD;
      LOAD:  next_state = CLEAR;
      CLEAR: next_state = HOLD;
      default: next_state = HOLD;
    endcase
  end
endmodule