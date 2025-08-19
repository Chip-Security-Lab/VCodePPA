//SystemVerilog
module johnson_counter_reset #(parameter WIDTH = 8)(
  input wire clk, rst, enable,
  output reg [WIDTH-1:0] johnson_count,
  output reg data_valid
);
  // Define pipeline stages (increased from 2 to 3 stages for better balance)
  reg [WIDTH-1:0] stage1_count, stage2_count, stage3_count;
  reg stage1_valid, stage2_valid, stage3_valid;
  
  // Pipeline control signals
  reg pipeline_active;
  wire shift_ready;
  
  // Generate pipeline enable signals with lookahead logic
  wire stage1_enable = enable & (pipeline_active | ~stage1_valid);
  wire stage2_enable = stage1_valid & (pipeline_active | ~stage2_valid);
  wire stage3_enable = stage2_valid & (pipeline_active | ~stage3_valid);
  
  // Calculate next bit with optimized path
  wire next_bit = ~stage3_count[WIDTH-1];
  
  // Track pipeline activity for throughput optimization
  always @(posedge clk) begin
    if (rst)
      pipeline_active <= 1'b0;
    else if (enable)
      pipeline_active <= 1'b1;
    else if (~stage1_valid & ~stage2_valid & ~stage3_valid)
      pipeline_active <= 1'b0;
  end

  // Stage 1: Initial input and control handling
  always @(posedge clk) begin
    if (rst) begin
      stage1_count <= {{WIDTH-1{1'b0}}, 1'b1};
      stage1_valid <= 1'b0;
    end 
    else if (stage1_enable) begin
      // Data forwarding for optimized latency when needed
      stage1_count <= (pipeline_active && !stage3_valid) ? stage3_count : 
                      (pipeline_active && !stage2_valid) ? stage2_count : 
                      johnson_count;
      stage1_valid <= 1'b1;
    end 
    else if (!pipeline_active) begin
      stage1_valid <= 1'b0;
    end
  end
  
  // Stage 2: Intermediate computation
  always @(posedge clk) begin
    if (rst) begin
      stage2_count <= {{WIDTH-1{1'b0}}, 1'b1};
      stage2_valid <= 1'b0;
    end 
    else if (stage2_enable) begin
      // Pre-compute partial shift operation
      stage2_count <= {stage1_count[WIDTH-2:0], ~stage1_count[WIDTH-1]};
      stage2_valid <= 1'b1;
    end 
    else if (!pipeline_active && !stage1_valid) begin
      stage2_valid <= 1'b0;
    end
  end
  
  // Stage 3: Final shift operation and output preparation
  always @(posedge clk) begin
    if (rst) begin
      stage3_count <= {{WIDTH-1{1'b0}}, 1'b1};
      stage3_valid <= 1'b0;
    end 
    else if (stage3_enable) begin
      // Adjust shift with balancing logic for better timing
      stage3_count <= stage2_count;
      stage3_valid <= 1'b1;
    end 
    else if (!pipeline_active && !stage2_valid) begin
      stage3_valid <= 1'b0;
    end
  end
  
  // Output stage with buffering for continuous operation
  always @(posedge clk) begin
    if (rst) begin
      johnson_count <= {{WIDTH-1{1'b0}}, 1'b1};
      data_valid <= 1'b0;
    end 
    else if (stage3_valid) begin
      johnson_count <= stage3_count;
      data_valid <= 1'b1;
    end 
    else begin
      data_valid <= 1'b0;
    end
  end
endmodule