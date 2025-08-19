//SystemVerilog
// Pipelined 8-bit adder module
// Transforms a simple combinational adder into a 2-stage pipeline.
// Stage 1: Register inputs.
// Stage 2: Perform addition on registered inputs and register the result.
module split_add(
  input wire        clk,    // Clock signal
  input wire        rst_n,  // Asynchronous active-low reset

  input wire [7:0]  m,      // First 8-bit input operand
  input wire [7:0]  n,      // Second 8-bit input operand

  output wire [8:0] total   // 9-bit pipelined sum of m and n
);

  //----------------------------------------------------------------------------
  // Internal Signals for Pipelined Data Flow
  //----------------------------------------------------------------------------

  // Stage 1: Registered inputs
  reg [7:0] data_m_s1_r;
  reg [7:0] data_n_s1_r;

  // Stage 2: Combinational sum calculation and registered output
  wire [8:0] sum_s2_comb;   // Combinational result of addition
  reg [8:0]  data_sum_s2_r; // Registered sum

  //----------------------------------------------------------------------------
  // Stage 1: Input Registers
  // Registers the input operands m and n
  // Using always_ff for explicit flip-flop inference
  //----------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_m_s1_r <= 8'b0;
      data_n_s1_r <= 8'b0;
    end else begin
      data_m_s1_r <= m;
      data_n_s1_r <= n;
    end
  end

  //----------------------------------------------------------------------------
  // Stage 2: Addition and Output Register
  // Performs addition on Stage 1 registered data and registers the result
  //----------------------------------------------------------------------------

  // Combinational addition
  assign sum_s2_comb = data_m_s1_r + data_n_s1_r;

  // Register the result of the addition
  // Using always_ff for explicit flip-flop inference
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_sum_s2_r <= 9'b0;
    end else begin
      data_sum_s2_r <= sum_s2_comb;
    end
  end

  //----------------------------------------------------------------------------
  // Final Output Assignment
  // The module output is the registered sum from Stage 2
  //----------------------------------------------------------------------------
  assign total = data_sum_s2_r;

endmodule