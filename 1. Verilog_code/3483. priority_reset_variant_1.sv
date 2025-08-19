//SystemVerilog
//IEEE 1364-2005 Verilog
module priority_reset(
  input clk, global_rst, subsystem_rst, local_rst,
  input [7:0] data_in,
  input ack,                   // Acknowledge signal from receiver
  output reg req,              // Request signal to receiver
  output reg [7:0] data_out
);

  // Pipeline stage 1 registers (Input stage)
  reg [7:0] data_stage1;
  reg valid_stage1;
  reg subsystem_rst_stage1, local_rst_stage1;
  
  // Pipeline stage 2 registers (Processing stage)
  reg [7:0] data_stage2;
  reg valid_stage2;
  
  // Pipeline stage 3 registers (Output stage)
  reg [7:0] data_stage3;
  reg valid_stage3;
  reg prev_ack;

  // Pipeline Stage 1: Input Capture and Reset Prioritization
  always @(posedge clk or posedge global_rst) begin
    if (global_rst) begin
      data_stage1 <= 8'h00;
      valid_stage1 <= 1'b0;
      subsystem_rst_stage1 <= 1'b0;
      local_rst_stage1 <= 1'b0;
    end else begin
      // Capture input data and reset signals
      data_stage1 <= data_in;
      subsystem_rst_stage1 <= subsystem_rst;
      local_rst_stage1 <= local_rst;
      valid_stage1 <= 1'b1; // Always valid after reset
    end
  end

  // Pipeline Stage 2: Data Processing and Reset Logic
  always @(posedge clk or posedge global_rst) begin
    if (global_rst) begin
      data_stage2 <= 8'h00;
      valid_stage2 <= 1'b0;
    end else begin
      valid_stage2 <= valid_stage1;
      
      // Apply reset priority logic
      if (subsystem_rst_stage1)
        data_stage2 <= 8'h01;
      else if (local_rst_stage1)
        data_stage2 <= 8'h02;
      else
        data_stage2 <= data_stage1;
    end
  end

  // Pipeline Stage 3: Handshake Control Logic
  always @(posedge clk or posedge global_rst) begin
    if (global_rst) begin
      data_stage3 <= 8'h00;
      valid_stage3 <= 1'b0;
    end else if (!req || (req && ack && !prev_ack)) begin
      // Load next data when handshake completes or no active request
      data_stage3 <= data_stage2;
      valid_stage3 <= valid_stage2;
    end
  end

  // Track previous ack state
  always @(posedge clk or posedge global_rst) begin
    if (global_rst)
      prev_ack <= 1'b0;
    else
      prev_ack <= ack;
  end

  // Output control with req-ack handshake
  always @(posedge clk or posedge global_rst) begin
    if (global_rst) begin
      data_out <= 8'h00;
      req <= 1'b0;
    end else if (valid_stage3 && !req) begin
      // Issue new request when data is ready and no active request
      data_out <= data_stage3;
      req <= 1'b1;
    end else if (req && ack && !prev_ack) begin
      // Complete handshake when ack rises
      req <= 1'b0;
    end
  end
  
endmodule