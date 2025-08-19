//SystemVerilog
module edge_triggered_intr_ctrl(
  input clk, rst_n,
  input [7:0] intr_in,
  input intr_ack,
  output reg [2:0] intr_num,
  output reg intr_req
);
  // Stage 1: Edge detection pipeline registers
  reg [7:0] intr_prev;
  reg [7:0] intr_edge_stage1;
  reg [7:0] intr_flag_stage1;
  reg valid_stage1;

  // Stage 2: Priority encoding pipeline registers
  reg [7:0] intr_flag_stage2;
  reg [2:0] intr_num_stage2;
  reg valid_stage2;
  reg intr_served_stage2;

  // Stage 3: Output stage registers
  reg intr_served_stage3;
  
  // Edge detection combinational logic
  wire [7:0] intr_edge = intr_in & ~intr_prev;
  wire [7:0] next_intr_flag = (intr_req && intr_ack && !intr_served_stage3) ? 8'h0 : 
                             (!intr_req ? (intr_flag_stage2 | intr_edge) : (intr_flag_stage2 | intr_edge));

  // Priority encoding combinational logic
  wire [2:0] next_intr_num;
  wire has_pending_intr = |next_intr_flag;
  wire should_update_num = has_pending_intr && (!intr_req || (intr_req && !intr_served_stage3));

  // Pipeline Stage 1: Edge detection and flag update
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_prev <= 8'h0;
      intr_edge_stage1 <= 8'h0;
      intr_flag_stage1 <= 8'h0;
      valid_stage1 <= 1'b0;
    end else begin
      intr_prev <= intr_in;
      intr_edge_stage1 <= intr_edge;
      intr_flag_stage1 <= next_intr_flag;
      valid_stage1 <= 1'b1; // Always valid after reset
    end
  end

  // Pipeline Stage 2: Priority encoding
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_flag_stage2 <= 8'h0;
      intr_num_stage2 <= 3'h0;
      valid_stage2 <= 1'b0;
      intr_served_stage2 <= 1'b0;
    end else if (valid_stage1) begin
      intr_flag_stage2 <= intr_flag_stage1;
      
      // Priority encoder logic
      if (should_update_num) begin
        casez (next_intr_flag)
          8'b???????1: intr_num_stage2 <= 3'd0;
          8'b??????10: intr_num_stage2 <= 3'd1;
          8'b?????100: intr_num_stage2 <= 3'd2;
          8'b????1000: intr_num_stage2 <= 3'd3;
          8'b???10000: intr_num_stage2 <= 3'd4;
          8'b??100000: intr_num_stage2 <= 3'd5;
          8'b?1000000: intr_num_stage2 <= 3'd6;
          8'b10000000: intr_num_stage2 <= 3'd7;
          default: intr_num_stage2 <= intr_num_stage2;
        endcase
      end
      
      // Update served status
      if (intr_req && intr_ack && !intr_served_stage3) begin
        intr_served_stage2 <= 1'b1;
      end else if (!intr_req) begin
        intr_served_stage2 <= 1'b0;
      end else begin
        intr_served_stage2 <= intr_served_stage3;
      end
      
      valid_stage2 <= valid_stage1;
    end
  end

  // Pipeline Stage 3: Output stage
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_num <= 3'h0;
      intr_req <= 1'b0;
      intr_served_stage3 <= 1'b0;
    end else if (valid_stage2) begin
      intr_num <= intr_num_stage2;
      intr_req <= |intr_flag_stage2;
      intr_served_stage3 <= intr_served_stage2;
    end
  end
endmodule