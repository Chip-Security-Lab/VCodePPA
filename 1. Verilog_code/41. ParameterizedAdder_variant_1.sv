//SystemVerilog
module adder_9 #(parameter WIDTH = 1) (
    input clk,
    input rst_n, // Active low reset
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] sum
);

  //----------------------------------------------------------------------------
  // Pipeline Stage 1: Input Registration
  // Registers input signals 'a' and 'b' to break the combinational path.
  // This helps in reducing the critical path delay and improving Fmax.
  // Split into separate blocks for potential PPA impact and modularity.
  //----------------------------------------------------------------------------
  reg [WIDTH-1:0] stage1_a_reg;
  reg [WIDTH-1:0] stage1_b_reg;

  // Register input 'a'
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage1_a_reg <= {WIDTH{1'b0}}; // Reset input 'a' to 0
    end else begin
      stage1_a_reg <= a;
    end
  end

  // Register input 'b'
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage1_b_reg <= {WIDTH{1'b0}}; // Reset input 'b' to 0
    end else begin
      stage1_b_reg <= b;
    end
  end

  //----------------------------------------------------------------------------
  // Pipeline Stage 1 (Combinational Part): Addition
  // Performs the addition operation on the registered inputs.
  // The combinational depth is now limited to just the adder logic,
  // driven by registers from Stage 1.
  //----------------------------------------------------------------------------
  wire [WIDTH-1:0] stage1_sum_comb;
  assign stage1_sum_comb = stage1_a_reg + stage1_b_reg;

  //----------------------------------------------------------------------------
  // Pipeline Stage 2: Output Registration
  // Registers the result of the addition from Stage 1.
  // This further reduces the critical path by capturing the result
  // at the end of the clock cycle.
  //----------------------------------------------------------------------------
  reg [WIDTH-1:0] sum_reg; // Registered sum output

  // Register the sum result
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sum_reg <= {WIDTH{1'b0}}; // Reset output register to 0
    end else begin
      sum_reg <= stage1_sum_comb;
    end
  end

  //----------------------------------------------------------------------------
  // Module Output
  // The final output 'sum' is driven by the registered value from Stage 2.
  // This results in a 1-cycle pipeline latency.
  //----------------------------------------------------------------------------
  assign sum = sum_reg;

endmodule