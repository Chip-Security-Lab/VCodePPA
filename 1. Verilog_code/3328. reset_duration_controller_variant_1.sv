//SystemVerilog
module reset_duration_controller #(
  parameter MIN_DURATION = 16'd100,
  parameter MAX_DURATION = 16'd10000
)(
  input clk,
  input trigger,
  input [15:0] requested_duration,
  output reg reset_active
);
  reg [15:0] counter = 16'd0;
  reg [15:0] actual_duration;

  wire [15:0] min_constrained;
  assign min_constrained = (requested_duration < MIN_DURATION) ? MIN_DURATION : requested_duration;
  wire [15:0] duration_limited;
  assign duration_limited = (min_constrained > MAX_DURATION) ? MAX_DURATION : min_constrained;

  typedef enum logic [1:0] {
    IDLE = 2'b00,
    ACTIVE = 2'b01
  } state_t;

  state_t current_state = IDLE, next_state;

  // Next state logic
  always @(*) begin
    case (current_state)
      IDLE: begin
        if (trigger)
          next_state = ACTIVE;
        else
          next_state = IDLE;
      end
      ACTIVE: begin
        if (counter == actual_duration - 1)
          next_state = IDLE;
        else
          next_state = ACTIVE;
      end
      default: next_state = IDLE;
    endcase
  end

  // Output and counter logic
  always @(posedge clk) begin
    actual_duration <= duration_limited;

    case (current_state)
      IDLE: begin
        reset_active <= 1'b0;
        counter <= 16'd0;
        if (trigger)
          reset_active <= 1'b1;
      end
      ACTIVE: begin
        reset_active <= 1'b1;
        if (counter == actual_duration - 1) begin
          reset_active <= 1'b0;
          counter <= 16'd0;
        end else begin
          counter <= counter + 16'd1;
        end
      end
      default: begin
        reset_active <= 1'b0;
        counter <= 16'd0;
      end
    endcase
    current_state <= next_state;
  end

endmodule