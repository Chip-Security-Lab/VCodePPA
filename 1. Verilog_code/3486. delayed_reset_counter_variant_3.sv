//SystemVerilog
module delayed_reset_counter #(parameter WIDTH = 8, DELAY = 3)(
  input wire clk,
  input wire rst_trigger,
  output reg [WIDTH-1:0] count_out
);
  // Pipeline registers for reset delay shift register
  reg [DELAY-1:0] delay_shift_stage1;
  reg [DELAY-1:0] delay_shift_stage2;
  
  // Pipeline registers for count
  reg [WIDTH-1:0] count_stage1;
  reg [WIDTH-1:0] count_stage2;
  
  // Pipeline valid signals
  reg valid_stage1, valid_stage2;
  
  // Delayed reset signals for each stage
  wire delayed_reset_stage1 = delay_shift_stage1[0];
  
  // Stage 1: Input and shift register processing
  always @(posedge clk) begin
    // First stage of pipeline - shift register update
    delay_shift_stage1 <= {rst_trigger, delay_shift_stage1[DELAY-1:1]};
    valid_stage1 <= 1'b1; // Data is always valid in this design
  end
  
  // Stage 2: Counter update based on delayed reset
  always @(posedge clk) begin
    // Pass shift register to next stage
    delay_shift_stage2 <= delay_shift_stage1;
    
    // Counter logic
    if (delayed_reset_stage1)
      count_stage1 <= {WIDTH{1'b0}};
    else
      count_stage1 <= count_stage1 + 1'b1;
      
    valid_stage2 <= valid_stage1;
  end
  
  // Stage 3: Output stage
  always @(posedge clk) begin
    if (valid_stage2) begin
      count_out <= count_stage1;
    end
  end
  
  // Initialize pipeline registers
  initial begin
    delay_shift_stage1 = {DELAY{1'b0}};
    delay_shift_stage2 = {DELAY{1'b0}};
    count_stage1 = {WIDTH{1'b0}};
    count_stage2 = {WIDTH{1'b0}};
    valid_stage1 = 1'b0;
    valid_stage2 = 1'b0;
    count_out = {WIDTH{1'b0}};
  end
endmodule