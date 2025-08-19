//SystemVerilog
module reset_handshake_monitor (
  input  wire clk,           // System clock
  input  wire reset_req,     // Reset request signal from source
  input  wire reset_ack,     // Reset acknowledge signal from target
  output reg  reset_active,  // Active reset signal indication
  output reg  timeout_error  // Timeout error indication
);

  // States for reset handshake FSM
  localparam IDLE      = 2'b00;
  localparam REQ_SENT  = 2'b01;
  localparam ACK_WAIT  = 2'b10;
  localparam COMPLETE  = 2'b11;

  // Register definitions
  reg [1:0] curr_state;
  reg [7:0] timeout_counter;
  reg       timeout_flag;
  
  // Registered input signals for timing optimization
  reg       reset_req_reg;
  reg       reset_ack_reg;
  
  // Capture input signals first to reduce input-to-register delay
  always @(posedge clk) begin
    reset_req_reg <= reset_req;
    reset_ack_reg <= reset_ack;
  end
  
  // Combined state transition and output logic
  // Moved combinational logic after input registers
  always @(posedge clk) begin
    // Default assignments
    case (curr_state)
      IDLE: begin
        if (reset_req_reg) begin
          curr_state <= REQ_SENT;
          reset_active <= 1'b1;
          timeout_error <= 1'b0;
          timeout_counter <= 8'd0;
          timeout_flag <= 1'b0;
        end else begin
          curr_state <= IDLE;
          reset_active <= 1'b0;
          timeout_error <= 1'b0;
        end
      end
      
      REQ_SENT: begin
        curr_state <= ACK_WAIT;
        reset_active <= 1'b1;
        // Keep timeout counter and flag unchanged
      end
      
      ACK_WAIT: begin
        if (reset_ack_reg) begin
          curr_state <= COMPLETE;
          reset_active <= 1'b0;
        end else if (timeout_flag) begin
          curr_state <= IDLE;
          reset_active <= 1'b0;
          timeout_error <= 1'b1;
        end else begin
          curr_state <= ACK_WAIT;
          reset_active <= 1'b1;
          
          // Timeout counter logic integrated here
          if (timeout_counter < 8'hFF) begin
            timeout_counter <= timeout_counter + 8'd1;
            timeout_flag <= 1'b0;
          end else begin
            timeout_flag <= 1'b1;
            timeout_error <= 1'b1;
          end
        end
      end
      
      COMPLETE: begin
        curr_state <= IDLE;
        reset_active <= 1'b0;
        // Keep timeout counters and flags unchanged
      end
      
      default: begin
        curr_state <= IDLE;
        reset_active <= 1'b0;
        timeout_error <= 1'b0;
        timeout_counter <= 8'd0;
        timeout_flag <= 1'b0;
      end
    endcase
  end

endmodule