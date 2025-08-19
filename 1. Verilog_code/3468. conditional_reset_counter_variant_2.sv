//SystemVerilog
module conditional_reset_counter #(parameter WIDTH = 12)(
  input clk, reset_n, condition, enable,
  output reg [WIDTH-1:0] value,
  // Pipeline control signals
  input valid_in,
  output reg valid_out,
  input ready_in,
  output reg ready_out
);
  // Pipeline registers for input signals
  reg condition_stage1, enable_stage1;
  reg condition_stage2, enable_stage2;
  
  // Pipeline data registers
  reg [WIDTH-1:0] value_stage1;
  reg [WIDTH-1:0] value_stage2;
  
  // Pipeline valid registers
  reg valid_stage1, valid_stage2;
  
  // Ready signal propagation (backward)
  wire stall = valid_out && !ready_in;
  
  // Stage 1: Input capture - condition signal
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      condition_stage1 <= 1'b0;
    end
    else if (!stall) begin
      condition_stage1 <= condition;
    end
  end
  
  // Stage 1: Input capture - enable signal
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      enable_stage1 <= 1'b0;
    end
    else if (!stall) begin
      enable_stage1 <= enable;
    end
  end
  
  // Stage 1: Input capture - valid signal
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      valid_stage1 <= 1'b0;
    end
    else if (!stall) begin
      valid_stage1 <= valid_in;
    end
  end
  
  // Stage 1: Input capture - value signal
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      value_stage1 <= {WIDTH{1'b0}};
    end
    else if (!stall) begin
      value_stage1 <= value;
    end
  end
  
  // Stage 2: Control signals propagation - condition
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      condition_stage2 <= 1'b0;
    end
    else if (!stall) begin
      condition_stage2 <= condition_stage1;
    end
  end
  
  // Stage 2: Control signals propagation - enable
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      enable_stage2 <= 1'b0;
    end
    else if (!stall) begin
      enable_stage2 <= enable_stage1;
    end
  end
  
  // Stage 2: Control signals propagation - valid
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      valid_stage2 <= 1'b0;
    end
    else if (!stall) begin
      valid_stage2 <= valid_stage1;
    end
  end
  
  // Stage 2: Calculate next counter value
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      value_stage2 <= {WIDTH{1'b0}};
    end
    else if (!stall) begin
      if (condition_stage1 && enable_stage1)
        value_stage2 <= {WIDTH{1'b0}}; // Conditional reset
      else if (enable_stage1)
        value_stage2 <= value_stage1 + 1'b1; // Increment
      else
        value_stage2 <= value_stage1; // Hold value
    end
  end
  
  // Final stage: Output value
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      value <= {WIDTH{1'b0}};
    end
    else if (!stall) begin
      value <= value_stage2;
    end
  end
  
  // Final stage: Valid signal
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      valid_out <= 1'b0;
    end
    else if (!stall) begin
      valid_out <= valid_stage2;
    end
  end
  
  // Ready signal generation
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n)
      ready_out <= 1'b1;
    else
      ready_out <= !stall;
  end
  
endmodule