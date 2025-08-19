//SystemVerilog
module reset_timeout_monitor (
  input wire clk,
  input wire reset_n,
  output reg reset_timeout_error
);
  // Increase pipeline stages for timeout calculation
  reg [7:0] timeout_stage1;
  reg [7:0] timeout_stage2;
  reg [7:0] timeout_stage3;
  
  // Pipeline registers for timeout reached signals
  reg timeout_reached_stage1;
  reg timeout_reached_stage2;
  reg timeout_reached_stage3;
  reg timeout_reached_stage4;
  
  // Stage 1: Increment and initial threshold detection
  always @(posedge clk) begin
    if (!reset_n) begin
      timeout_stage1 <= 8'd0;
      timeout_reached_stage1 <= 1'b0;
    end else if (timeout_stage3 < 8'hFF) begin
      timeout_stage1 <= timeout_stage3 + 1'b1;
      timeout_reached_stage1 <= (timeout_stage3 + 1'b1 == 8'hFF);
    end else begin
      timeout_stage1 <= timeout_stage3;
      timeout_reached_stage1 <= 1'b1;
    end
  end
  
  // Stage 2: Pipeline timeout value and reached signal
  always @(posedge clk) begin
    if (!reset_n) begin
      timeout_stage2 <= 8'd0;
      timeout_reached_stage2 <= 1'b0;
    end else begin
      timeout_stage2 <= timeout_stage1;
      timeout_reached_stage2 <= timeout_reached_stage1;
    end
  end
  
  // Stage 3: Pipeline timeout value and reached signal
  always @(posedge clk) begin
    if (!reset_n) begin
      timeout_stage3 <= 8'd0;
      timeout_reached_stage3 <= 1'b0;
    end else begin
      timeout_stage3 <= timeout_stage2;
      timeout_reached_stage3 <= timeout_reached_stage2;
    end
  end
  
  // Stage 4: Final timeout reached signal
  always @(posedge clk) begin
    if (!reset_n) begin
      timeout_reached_stage4 <= 1'b0;
    end else begin
      timeout_reached_stage4 <= timeout_reached_stage3;
    end
  end

  // Output register - moved to a separate pipeline stage
  always @(posedge clk) begin
    if (!reset_n) begin
      reset_timeout_error <= 1'b0;
    end else begin
      reset_timeout_error <= timeout_reached_stage4;
    end
  end
endmodule