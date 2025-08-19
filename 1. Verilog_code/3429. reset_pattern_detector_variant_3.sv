//SystemVerilog
module reset_pattern_detector (
  input wire clk,
  input wire req,
  output reg ack,
  output reg pattern_detected
);
  reg [7:0] shift_reg;
  reg req_r;
  localparam PATTERN = 8'b10101010;
  
  // Edge detection for req signal
  always @(posedge clk) begin
    req_r <= req;
  end
  
  // Pattern detection logic with handshake protocol using case statement
  always @(posedge clk) begin
    case ({req, req_r})
      2'b10: begin // Request rising edge (req=1, req_r=0)
        shift_reg <= {shift_reg[6:0], req};
        pattern_detected <= (shift_reg == PATTERN);
        ack <= 1'b1;
      end
      2'b01: begin // Request falling edge (req=0, req_r=1)
        ack <= 1'b0;
      end
      default: begin // No edge (2'b00 or 2'b11)
        // Maintain current state
      end
    endcase
  end
endmodule