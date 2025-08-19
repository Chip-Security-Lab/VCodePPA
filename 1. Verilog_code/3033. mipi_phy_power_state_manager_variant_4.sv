//SystemVerilog
module mipi_phy_power_state_manager (
  // AXI-Stream Interface
  input wire aclk,
  input wire aresetn,
  
  // AXI-Stream Slave Interface
  input wire s_axis_tvalid,
  output reg s_axis_tready,
  input wire [15:0] s_axis_tdata,
  input wire s_axis_tlast,
  
  // AXI-Stream Master Interface
  output reg m_axis_tvalid,
  input wire m_axis_tready,
  output reg [15:0] m_axis_tdata,
  output reg m_axis_tlast
);

  localparam OFF = 2'b00, SLEEP = 2'b01, ULPS = 2'b10, ON = 2'b11;
  localparam IDLE = 2'b01, TRANSITION = 2'b10;
  
  reg [1:0] state, next_state;
  reg [15:0] timeout_counter;
  reg timeout_en;
  reg [1:0] power_mode_req;
  reg [3:0] lane_mask;
  reg [1:0] power_mode_ack;
  reg [3:0] lane_lp_state;
  reg [3:0] lane_hs_en;
  
  // AXI-Stream Slave Interface Logic
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      s_axis_tready <= 1'b1;
      power_mode_req <= 2'b00;
      lane_mask <= 4'h0;
    end else if (s_axis_tvalid && s_axis_tready) begin
      power_mode_req <= s_axis_tdata[1:0];
      lane_mask <= s_axis_tdata[5:2];
    end
  end
  
  // State Machine Logic
  always @(*) begin
    next_state = state;
    if (state == IDLE && power_mode_req != power_mode_ack)
      next_state = TRANSITION;
    else if (state == TRANSITION && timeout_counter >= 16'd1000)
      next_state = IDLE;
  end
  
  // Main State Machine
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      state <= IDLE;
      power_mode_ack <= 2'b00;
      lane_lp_state <= 4'h0;
      lane_hs_en <= 4'h0;
      timeout_counter <= 16'd0;
      timeout_en <= 1'b0;
      m_axis_tvalid <= 1'b0;
      m_axis_tdata <= 16'd0;
      m_axis_tlast <= 1'b0;
    end else begin
      state <= next_state;
      
      if (timeout_en)
        timeout_counter <= timeout_counter + 1'b1;
      else
        timeout_counter <= 16'd0;
      
      if (state == IDLE && power_mode_req != power_mode_ack)
        timeout_en <= 1'b1;
      else if (state == TRANSITION && timeout_counter >= 16'd1000)
        timeout_en <= 1'b0;
      
      if (state == TRANSITION) begin
        if (power_mode_req == OFF) begin
          lane_hs_en <= 4'h0;
          lane_lp_state <= 4'h0;
        end
        else if (power_mode_req == SLEEP) begin
          lane_hs_en <= 4'h0;
          lane_lp_state <= lane_mask;
        end
        else if (power_mode_req == ULPS) begin
          lane_hs_en <= 4'h0;
          lane_lp_state <= lane_mask;
        end
        else if (power_mode_req == ON) begin
          lane_hs_en <= lane_mask;
          lane_lp_state <= 4'h0;
        end
      end
      
      if (state == TRANSITION && timeout_counter >= 16'd1000) begin
        power_mode_ack <= power_mode_req;
        m_axis_tvalid <= 1'b1;
        m_axis_tdata <= {12'd0, lane_hs_en, lane_lp_state, power_mode_ack};
        m_axis_tlast <= 1'b1;
      end else if (m_axis_tready) begin
        m_axis_tvalid <= 1'b0;
        m_axis_tlast <= 1'b0;
      end
    end
  end
endmodule