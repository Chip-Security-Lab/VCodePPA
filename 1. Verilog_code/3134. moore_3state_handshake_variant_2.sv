//SystemVerilog
module moore_3state_handshake(
  input  clk,
  input  rst,
  input  start,
  input  ack,
  output reg done
);
  reg [1:0] state, next_state;
  localparam IDLE     = 2'b00,
             WAIT_ACK = 2'b01,
             COMPLETE = 2'b10;

  always @(posedge clk or posedge rst) begin
    if (rst) state <= IDLE;
    else     state <= next_state;
  end

  always @* begin
    case (state)
      IDLE:      next_state = start ? WAIT_ACK : IDLE;
      WAIT_ACK:  next_state = ack   ? COMPLETE : WAIT_ACK;
      COMPLETE:  next_state = IDLE;
    endcase
  end

  always @* done = (state == COMPLETE);
  
  // Recursive Karatsuba multiplier for 2-bit numbers
  function [3:0] karatsuba;
    input [1:0] x, y;
    reg [1:0] x0, x1, y0, y1;
    reg [1:0] z0, z1, z2;
    begin
      if (x == 0 || y == 0) begin
        karatsuba = 0;
      end else begin
        x0 = x[0]; x1 = x[1];
        y0 = y[0]; y1 = y[1];
        
        z0 = x0 * y0; // base case
        z1 = (x0 + x1) * (y0 + y1) - z0 - (x1 * y1); // z1 = (x0 + x1)(y0 + y1) - z0 - z2
        z2 = x1 * y1; // base case
        
        karatsuba = (z2 << 2) + (z1 << 1) + z0; // combine results
      end
    end
  endfunction

endmodule