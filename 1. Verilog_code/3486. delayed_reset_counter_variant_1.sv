//SystemVerilog
module delayed_reset_counter #(parameter WIDTH = 8, DELAY = 3)(
  input wire clk,
  input wire rst_trigger,
  output reg [WIDTH-1:0] count
);
  // Reset delay shift register with efficient packing
  (* shreg_extract = "yes" *) reg [DELAY-1:0] reset_delay_sr;
  
  // Pipeline registers with clear naming - increased pipeline stages
  reg [WIDTH-1:0] count_pipe1;
  reg [WIDTH-1:0] count_pipe2;
  reg [WIDTH-1:0] count_pipe3;
  reg [WIDTH-1:0] count_pipe4;
  
  // Valid flags for pipeline control
  reg valid_pipe1 = 1'b0;
  reg valid_pipe2 = 1'b0;
  reg valid_pipe3 = 1'b0;
  reg valid_pipe4 = 1'b0;
  
  // Reset signal from shift register
  wire reset_active = reset_delay_sr[0];
  
  // Intermediate calculation signals
  reg [WIDTH/2-1:0] count_lower_half;
  reg [WIDTH/2-1:0] count_upper_half;
  reg carry;
  
  // Stage 1: Reset delay shift register
  always @(posedge clk) begin
    // Optimized shift register implementation
    reset_delay_sr <= {rst_trigger, reset_delay_sr[DELAY-1:1]};
    valid_pipe1 <= 1'b1; // Always valid after first cycle
  end
  
  // Stage 2: Lower half counter calculation
  always @(posedge clk) begin
    if (valid_pipe1) begin
      if (reset_active) begin
        count_lower_half <= {(WIDTH/2){1'b0}};
        carry <= 1'b0;
      end else begin
        {carry, count_lower_half} <= count[WIDTH/2-1:0] + 1'b1;
      end
      valid_pipe2 <= valid_pipe1;
    end
  end
  
  // Stage 3: Upper half counter calculation
  always @(posedge clk) begin
    if (valid_pipe2) begin
      if (reset_active) begin
        count_upper_half <= {(WIDTH/2){1'b0}};
      end else begin
        count_upper_half <= count[WIDTH-1:WIDTH/2] + carry;
      end
      count_pipe1 <= {count_upper_half, count_lower_half};
      valid_pipe3 <= valid_pipe2;
    end
  end
  
  // Stage 4: First output pipeline stage
  always @(posedge clk) begin
    if (valid_pipe3) begin
      count_pipe2 <= count_pipe1;
      valid_pipe4 <= valid_pipe3;
    end
  end
  
  // Stage 5: Second output pipeline stage
  always @(posedge clk) begin
    if (valid_pipe4) begin
      count_pipe3 <= count_pipe2;
      count_pipe4 <= count_pipe3;
      count <= count_pipe4;
    end
  end
endmodule