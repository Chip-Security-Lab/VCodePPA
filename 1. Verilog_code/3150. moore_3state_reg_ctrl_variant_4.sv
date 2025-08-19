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
  wire [WIDTH-1:0] sub_result;
  wire [WIDTH-1:0] twos_comp;
  wire [WIDTH-1:0] add_result;
  
  // 2's complement subtraction implementation
  assign twos_comp = ~din + 1'b1;
  assign add_result = dout + twos_comp;
  assign sub_result = add_result[WIDTH-1:0];

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state <= HOLD;
      dout  <= 0;
    end else begin
      state <= next_state;
      case (state)
        LOAD:  dout <= sub_result;
        CLEAR: dout <= 0;
      endcase
    end
  end

  always @* begin
    case (state)
      HOLD:  next_state = start ? LOAD : HOLD;
      LOAD:  next_state = CLEAR;
      CLEAR: next_state = HOLD;
    endcase
  end
endmodule