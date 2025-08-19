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
  
  reg [2:0] state, next_state;
  reg [15:0] timeout_counter;
  reg timeout_en;
  
  // Pipeline stage 1 registers
  reg [3:0] lane_mask_stage1;
  reg [1:0] power_mode_req_stage1;
  
  // Pipeline stage 2 registers
  reg [3:0] lane_mask_stage2;
  reg [1:0] power_mode_req_stage2;
  
  // Pipeline stage 3 registers
  reg [3:0] lane_mask_stage3;
  reg [1:0] power_mode_req_stage3;
  reg [3:0] h0_stage3;
  reg [3:0] d0_stage3;
  
  // Pipeline stage 4 registers
  reg [3:0] h0_stage4;
  reg [3:0] d0_stage4;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= 3'd0;
      power_mode_ack <= 2'b00;
      lane_lp_state <= 4'h0;
      lane_hs_en <= 4'h0;
      timeout_counter <= 16'd0;
      timeout_en <= 1'b0;
      lane_mask_stage1 <= 4'h0;
      lane_mask_stage2 <= 4'h0;
      lane_mask_stage3 <= 4'h0;
      power_mode_req_stage1 <= 2'b00;
      power_mode_req_stage2 <= 2'b00;
      power_mode_req_stage3 <= 2'b00;
      h0_stage3 <= 4'h0;
      d0_stage3 <= 4'h0;
      h0_stage4 <= 4'h0;
      d0_stage4 <= 4'h0;
    end else begin
      // Stage 1: Input buffering
      lane_mask_stage1 <= lane_mask;
      power_mode_req_stage1 <= power_mode_req;
      
      // Stage 2: Additional buffering
      lane_mask_stage2 <= lane_mask_stage1;
      power_mode_req_stage2 <= power_mode_req_stage1;
      
      // Stage 3: State transition and control logic
      lane_mask_stage3 <= lane_mask_stage2;
      power_mode_req_stage3 <= power_mode_req_stage2;
      
      if (timeout_en) timeout_counter <= timeout_counter + 1'b1;
      else timeout_counter <= 16'd0;
      
      case (state)
        3'd0: begin // IDLE
          if (power_mode_req_stage3 != power_mode_ack) begin
            state <= 3'd1;
            timeout_en <= 1'b1;
          end
        end
        3'd1: begin // TRANSITION
          case (power_mode_req_stage3)
            OFF: begin 
              h0_stage3 <= 4'h0; 
              d0_stage3 <= 4'h0; 
            end
            SLEEP: begin 
              h0_stage3 <= 4'h0; 
              d0_stage3 <= lane_mask_stage3; 
            end
            ULPS: begin 
              h0_stage3 <= 4'h0; 
              d0_stage3 <= lane_mask_stage3; 
            end
            ON: begin 
              h0_stage3 <= lane_mask_stage3; 
              d0_stage3 <= 4'h0; 
            end
          endcase
          
          // Stage 4: Output buffering
          h0_stage4 <= h0_stage3;
          d0_stage4 <= d0_stage3;
          
          // Final output assignment
          lane_hs_en <= h0_stage4;
          lane_lp_state <= d0_stage4;
          
          if (timeout_counter >= 16'd1000) begin
            power_mode_ack <= power_mode_req_stage3;
            state <= 3'd0;
            timeout_en <= 1'b0;
          end
        end
      endcase
    end
  end
endmodule