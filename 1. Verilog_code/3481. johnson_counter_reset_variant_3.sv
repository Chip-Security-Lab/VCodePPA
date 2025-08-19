//SystemVerilog
module johnson_counter_reset #(parameter WIDTH = 8)(
  input clk, rst, enable,
  output [WIDTH-1:0] johnson_count
);
  // Pipeline stage 1 registers
  reg [WIDTH-1:0] internal_count_stage1;
  reg [WIDTH-1:0] next_count_stage1;
  reg enable_stage1, rst_stage1;
  
  // Pipeline stage 2 registers
  reg [WIDTH-1:0] internal_count_stage2;
  reg [WIDTH-1:0] next_count_stage2;
  
  // Pipeline stage 3 registers
  reg [WIDTH-1:0] internal_count_stage3;
  
  // Stage 1: Register inputs and initial processing
  always @(posedge clk) begin
    rst_stage1 <= rst;
    enable_stage1 <= enable;
    internal_count_stage1 <= internal_count_stage3;
  end
  
  // Stage 1: Compute partial next state logic
  always @(posedge clk) begin
    if (rst)
      next_count_stage1 <= {{WIDTH-1{1'b0}}, 1'b1};
    else
      next_count_stage1 <= internal_count_stage1;
  end
  
  // Stage 2: Continue with next state computation
  always @(posedge clk) begin
    if (rst_stage1)
      next_count_stage2 <= next_count_stage1;
    else if (enable_stage1)
      next_count_stage2 <= {internal_count_stage1[WIDTH-2:0], ~internal_count_stage1[WIDTH-1]};
    else
      next_count_stage2 <= internal_count_stage1;
  end
  
  // Stage 2: Additional processing
  always @(posedge clk) begin
    internal_count_stage2 <= next_count_stage2;
  end
  
  // Stage 3: Final stage and output preparation
  always @(posedge clk) begin
    internal_count_stage3 <= internal_count_stage2;
  end
  
  // Output assignment
  assign johnson_count = internal_count_stage3;
  
endmodule