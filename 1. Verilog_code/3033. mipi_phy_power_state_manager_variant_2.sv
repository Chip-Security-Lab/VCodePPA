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
  
  // Pipeline stage signals
  wire [1:0] power_mode_req_stage1, power_mode_req_stage2;
  wire [3:0] lane_mask_stage1, lane_mask_stage2;
  wire [1:0] power_mode_ack_stage1, power_mode_ack_stage2;
  wire [3:0] lane_lp_state_stage1, lane_lp_state_stage2;
  wire [3:0] lane_hs_en_stage1, lane_hs_en_stage2;
  wire state_transition_done_stage1, state_transition_done_stage2;
  wire timeout_done_stage1, timeout_done_stage2;
  
  // Stage 1: Input processing and state transition
  input_pipeline_stage1 input_pipe_stage1 (
    .clk(clk),
    .reset_n(reset_n),
    .power_mode_req(power_mode_req),
    .lane_mask(lane_mask),
    .power_mode_req_out(power_mode_req_stage1),
    .lane_mask_out(lane_mask_stage1)
  );
  
  state_controller_stage1 state_ctrl_stage1 (
    .clk(clk),
    .reset_n(reset_n),
    .power_mode_req_pipe(power_mode_req_stage1),
    .power_mode_ack(power_mode_ack),
    .state_transition_done(state_transition_done_stage1)
  );
  
  // Stage 2: Timeout and lane control
  timeout_counter_stage2 timeout_stage2 (
    .clk(clk),
    .reset_n(reset_n),
    .timeout_en(state_transition_done_stage1),
    .timeout_done(timeout_done_stage2)
  );
  
  lane_controller_stage2 lane_ctrl_stage2 (
    .clk(clk),
    .reset_n(reset_n),
    .power_mode_req_pipe(power_mode_req_stage1),
    .lane_mask_pipe(lane_mask_stage1),
    .timeout_done(timeout_done_stage2),
    .power_mode_ack_next(power_mode_ack_stage2),
    .lane_lp_state_next(lane_lp_state_stage2),
    .lane_hs_en_next(lane_hs_en_stage2)
  );
  
  // Output pipeline stage
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      power_mode_ack <= 2'b00;
      lane_lp_state <= 4'h0;
      lane_hs_en <= 4'h0;
    end else begin
      power_mode_ack <= power_mode_ack_stage2;
      lane_lp_state <= lane_lp_state_stage2;
      lane_hs_en <= lane_hs_en_stage2;
    end
  end
endmodule

module input_pipeline_stage1 (
  input wire clk, reset_n,
  input wire [1:0] power_mode_req,
  input wire [3:0] lane_mask,
  output reg [1:0] power_mode_req_out,
  output reg [3:0] lane_mask_out
);
  reg [1:0] power_mode_req_reg;
  reg [3:0] lane_mask_reg;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      power_mode_req_reg <= 2'b00;
      lane_mask_reg <= 4'h0;
      power_mode_req_out <= 2'b00;
      lane_mask_out <= 4'h0;
    end else begin
      power_mode_req_reg <= power_mode_req;
      lane_mask_reg <= lane_mask;
      power_mode_req_out <= power_mode_req_reg;
      lane_mask_out <= lane_mask_reg;
    end
  end
endmodule

module state_controller_stage1 (
  input wire clk, reset_n,
  input wire [1:0] power_mode_req_pipe,
  input wire [1:0] power_mode_ack,
  output reg state_transition_done
);
  reg [2:0] state, next_state;
  reg state_transition_done_reg;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= 3'd0;
      state_transition_done_reg <= 1'b0;
      state_transition_done <= 1'b0;
    end else begin
      case (state)
        3'd0: begin
          if (power_mode_req_pipe != power_mode_ack) begin
            state <= 3'd1;
            state_transition_done_reg <= 1'b1;
          end
        end
        3'd1: begin
          state <= 3'd0;
          state_transition_done_reg <= 1'b0;
        end
      endcase
      state_transition_done <= state_transition_done_reg;
    end
  end
endmodule

module timeout_counter_stage2 (
  input wire clk, reset_n,
  input wire timeout_en,
  output reg timeout_done
);
  reg [15:0] timeout_counter;
  reg timeout_done_reg;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      timeout_counter <= 16'd0;
      timeout_done_reg <= 1'b0;
      timeout_done <= 1'b0;
    end else begin
      if (timeout_en) begin
        timeout_counter <= timeout_counter + 1'b1;
        if (timeout_counter >= 16'd1000) begin
          timeout_done_reg <= 1'b1;
        end
      end else begin
        timeout_counter <= 16'd0;
        timeout_done_reg <= 1'b0;
      end
      timeout_done <= timeout_done_reg;
    end
  end
endmodule

module lane_controller_stage2 (
  input wire clk, reset_n,
  input wire [1:0] power_mode_req_pipe,
  input wire [3:0] lane_mask_pipe,
  input wire timeout_done,
  output reg [1:0] power_mode_ack_next,
  output reg [3:0] lane_lp_state_next,
  output reg [3:0] lane_hs_en_next
);
  localparam OFF = 2'b00, SLEEP = 2'b01, ULPS = 2'b10, ON = 2'b11;
  
  reg [1:0] power_mode_ack_reg;
  reg [3:0] lane_lp_state_reg;
  reg [3:0] lane_hs_en_reg;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      power_mode_ack_reg <= 2'b00;
      lane_lp_state_reg <= 4'h0;
      lane_hs_en_reg <= 4'h0;
      power_mode_ack_next <= 2'b00;
      lane_lp_state_next <= 4'h0;
      lane_hs_en_next <= 4'h0;
    end else if (timeout_done) begin
      power_mode_ack_reg <= power_mode_req_pipe;
      
      case (power_mode_req_pipe)
        OFF: begin 
          lane_hs_en_reg <= 4'h0; 
          lane_lp_state_reg <= 4'h0; 
        end
        SLEEP: begin 
          lane_hs_en_reg <= 4'h0; 
          lane_lp_state_reg <= lane_mask_pipe; 
        end
        ULPS: begin 
          lane_hs_en_reg <= 4'h0; 
          lane_lp_state_reg <= lane_mask_pipe; 
        end
        ON: begin 
          lane_hs_en_reg <= lane_mask_pipe; 
          lane_lp_state_reg <= 4'h0; 
        end
      endcase
      
      power_mode_ack_next <= power_mode_ack_reg;
      lane_lp_state_next <= lane_lp_state_reg;
      lane_hs_en_next <= lane_hs_en_reg;
    end
  end
endmodule