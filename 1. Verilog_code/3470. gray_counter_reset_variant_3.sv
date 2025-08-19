//SystemVerilog
// SystemVerilog
module gray_counter_reset #(parameter WIDTH = 4)(
  input clk, rst, enable,
  output reg [WIDTH-1:0] gray_count
);
  // Manchester carry chain signals
  wire [WIDTH:0] carry;
  wire [WIDTH-1:0] sum;
  wire [WIDTH-1:0] p; // Propagate signals
  wire [WIDTH-1:0] g; // Generate signals
  reg [WIDTH-1:0] binary_count;
  wire [WIDTH-1:0] next_binary_count;
  wire [WIDTH-1:0] next_gray_count;
  
  // Manchester carry chain adder implementation
  assign carry[0] = 1'b0; // Initial carry-in is 0
  
  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin: manchester_adder
      // Generate p (propagate) and g (generate) signals
      assign p[i] = binary_count[i];
      assign g[i] = 1'b0; // For +1 operation, all generate signals are 0
      
      // Carry computation using Manchester carry chain
      assign carry[i+1] = g[i] | (p[i] & carry[i]);
      
      // Sum computation
      assign sum[i] = p[i] ^ carry[i];
    end
  endgenerate
  
  // Pre-compute next values (moved before registers)
  assign next_binary_count = (rst) ? {WIDTH{1'b0}} : 
                             (enable) ? sum : binary_count;
  
  assign next_gray_count = (rst) ? {WIDTH{1'b0}} :
                           (enable) ? (sum ^ (sum >> 1)) : gray_count;
  
  // Register stage moved after combinational logic
  always @(posedge clk) begin
    binary_count <= next_binary_count;
    gray_count <= next_gray_count;
  end
endmodule