//SystemVerilog
module moore_5state_advanced_traffic(
  input  wire       clk,
  input  wire       rst,
  output reg  [2:0] light
);
  // State definitions with descriptive names
  localparam [2:0] STATE_GREEN      = 3'b000,
                   STATE_GREEN_YELLOW = 3'b001,
                   STATE_YELLOW     = 3'b010,
                   STATE_RED        = 3'b011,
                   STATE_RED_YELLOW = 3'b100;
  
  // State registers to create proper pipeline structure
  reg [2:0] current_state, next_state;
  reg [2:0] light_pattern;
  reg [2:0] state_counter;
  
  // Sequential logic for state transition
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      current_state <= STATE_GREEN;
      state_counter <= 3'b000;
    end
    else begin
      current_state <= next_state;
      state_counter <= state_counter + 1;
    end
  end
  
  // Combinational logic for next state determination
  always @(*) begin
    case (current_state)
      STATE_GREEN:      next_state = (state_counter == 3'b111) ? STATE_GREEN_YELLOW : STATE_GREEN;
      STATE_GREEN_YELLOW: next_state = (state_counter == 3'b111) ? STATE_YELLOW : STATE_GREEN_YELLOW;
      STATE_YELLOW:     next_state = (state_counter == 3'b111) ? STATE_RED : STATE_YELLOW;
      STATE_RED:        next_state = (state_counter == 3'b111) ? STATE_RED_YELLOW : STATE_RED;
      STATE_RED_YELLOW: next_state = (state_counter == 3'b111) ? STATE_GREEN : STATE_RED_YELLOW;
      default:          next_state = STATE_GREEN;
    endcase
  end
  
  // Light pattern encoding
  always @(posedge clk or posedge rst) begin
    if (rst)
      light_pattern <= 3'b100;
    else begin
      case (current_state)
        STATE_GREEN:      light_pattern <= 3'b100;
        STATE_GREEN_YELLOW: light_pattern <= 3'b110;
        STATE_YELLOW:     light_pattern <= 3'b010;
        STATE_RED:        light_pattern <= 3'b001;
        STATE_RED_YELLOW: light_pattern <= 3'b011;
        default:          light_pattern <= 3'b100;
      endcase
    end
  end
  
  // Output stage
  always @(posedge clk or posedge rst) begin
    if (rst)
      light <= 3'b100;
    else
      light <= light_pattern;
  end
  
endmodule