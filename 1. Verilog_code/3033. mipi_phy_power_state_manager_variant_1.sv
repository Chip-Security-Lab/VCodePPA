//SystemVerilog
module mipi_phy_power_state_manager (
  input wire clk, reset_n,
  input wire [1:0] power_mode_req,
  input wire [3:0] lane_mask,
  output reg [1:0] power_mode_ack,
  output reg [3:0] lane_lp_state,
  output reg [3:0] lane_hs_en
);

  localparam OFF = 2'b00, SLEEP = 2'b01, ULPS = 2'b10, ON = 2'b11;
  localparam IDLE = 2'b01, TRANSITION = 2'b10;
  localparam TIMEOUT_THRESHOLD = 16'd1000;

  reg [1:0] state, next_state;
  reg [15:0] timeout_counter;
  reg timeout_en;
  reg [1:0] power_mode_req_reg;
  reg [3:0] lane_mask_reg;
  wire transition_complete;
  wire [3:0] next_lane_hs_en;
  wire [3:0] next_lane_lp_state;

  // Pre-compute next state values
  assign next_lane_hs_en = (power_mode_req_reg == ON) ? lane_mask_reg : 4'h0;
  assign next_lane_lp_state = (power_mode_req_reg == OFF) ? 4'h0 : 
                             ((power_mode_req_reg == ON) ? 4'h0 : lane_mask_reg);
  assign transition_complete = (timeout_counter >= TIMEOUT_THRESHOLD);

  // Register inputs to reduce timing paths
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      power_mode_req_reg <= 2'b00;
      lane_mask_reg <= 4'h0;
    end else begin
      power_mode_req_reg <= power_mode_req;
      lane_mask_reg <= lane_mask;
    end
  end

  // Main state machine
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= IDLE;
      power_mode_ack <= 2'b00;
      lane_lp_state <= 4'h0;
      lane_hs_en <= 4'h0;
      timeout_counter <= 16'd0;
      timeout_en <= 1'b0;
    end else begin
      // Counter logic
      timeout_counter <= timeout_en ? (timeout_counter + 1'b1) : 16'd0;

      case (state)
        IDLE: begin
          if (power_mode_req_reg != power_mode_ack) begin
            state <= TRANSITION;
            timeout_en <= 1'b1;
          end
        end
        TRANSITION: begin
          lane_hs_en <= next_lane_hs_en;
          lane_lp_state <= next_lane_lp_state;
          
          if (transition_complete) begin
            power_mode_ack <= power_mode_req_reg;
            state <= IDLE;
            timeout_en <= 1'b0;
          end
        end
      endcase
    end
  end
endmodule