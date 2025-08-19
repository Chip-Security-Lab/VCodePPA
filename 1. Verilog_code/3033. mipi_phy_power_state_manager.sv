module mipi_phy_power_state_manager (
  input wire clk, reset_n,
  input wire [1:0] power_mode_req, // 00: OFF, 01: SLEEP, 10: ULPS, 11: ON
  input wire [3:0] lane_mask, // Which lanes to control
  output reg [1:0] power_mode_ack,
  output reg [3:0] lane_lp_state,
  output reg [3:0] lane_hs_en
);
  localparam OFF = 2'b00, SLEEP = 2'b01, ULPS = 2'b10, ON = 2'b11;
  
  reg [2:0] state, next_state;
  reg [15:0] timeout_counter;
  reg timeout_en;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= 3'd0;
      power_mode_ack <= 2'b00;
      lane_lp_state <= 4'h0;
      lane_hs_en <= 4'h0;
      timeout_counter <= 16'd0;
      timeout_en <= 1'b0;
    end else begin
      if (timeout_en) timeout_counter <= timeout_counter + 1'b1;
      else timeout_counter <= 16'd0;
      
      case (state)
        3'd0: begin // IDLE
          if (power_mode_req != power_mode_ack) begin
            state <= 3'd1;
            timeout_en <= 1'b1;
          end
        end
        3'd1: begin // TRANSITION
          case (power_mode_req)
            OFF: begin lane_hs_en <= 4'h0; lane_lp_state <= 4'h0; end
            SLEEP: begin lane_hs_en <= 4'h0; lane_lp_state <= lane_mask; end
            ULPS: begin lane_hs_en <= 4'h0; lane_lp_state <= lane_mask; end
            ON: begin lane_hs_en <= lane_mask; lane_lp_state <= 4'h0; end
          endcase
          if (timeout_counter >= 16'd1000) begin
            power_mode_ack <= power_mode_req;
            state <= 3'd0;
            timeout_en <= 1'b0;
          end
        end
      endcase
    end
  end
endmodule