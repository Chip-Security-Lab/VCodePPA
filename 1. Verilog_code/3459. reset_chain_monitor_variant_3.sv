//SystemVerilog
module reset_chain_monitor (
  input wire clk,
  input wire [3:0] reset_chain,
  input wire ready,         // Ready signal from receiver
  output reg valid,         // Valid signal indicating data is valid
  output reg [3:0] error_data  // Output data
);

  reg error_detected;
  reg [1:0] handshake_state;
  
  localparam IDLE = 2'b00;
  localparam VALID_ASSERTED = 2'b01;
  localparam TRANSFER_DONE = 2'b10;
  
  // Error detection logic
  always @(posedge clk) begin
    if (reset_chain != 4'b0000 && reset_chain != 4'b1111)
      error_detected <= 1'b1;
    else 
      error_detected <= 1'b0;
  end
  
  // Valid-Ready handshake logic
  always @(posedge clk) begin
    case (handshake_state)
      IDLE: begin
        if (error_detected) begin
          valid <= 1'b1;
          error_data <= reset_chain;
          handshake_state <= VALID_ASSERTED;
        end
      end
      
      VALID_ASSERTED: begin
        if (ready) begin
          handshake_state <= TRANSFER_DONE;
        end
      end
      
      TRANSFER_DONE: begin
        valid <= 1'b0;
        if (!ready || !valid) begin
          handshake_state <= IDLE;
        end
      end
      
      default: handshake_state <= IDLE;
    endcase
  end
  
endmodule