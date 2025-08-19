//SystemVerilog
//IEEE 1364-2005
module prio_enc_sync_rst #(parameter WIDTH=8, ADDR=3)(
  input clk, rst_n,
  input [WIDTH-1:0] req_in,
  output reg [ADDR-1:0] addr_out
);
  
  wire [ADDR-1:0] encoded_addr;
  wire valid;
  
  // Manchester carry chain encoder implementation
  manchester_carry_encoder #(
    .WIDTH(WIDTH),
    .ADDR(ADDR)
  ) manchester_encoder_inst (
    .req_in(req_in),
    .addr_out(encoded_addr),
    .valid(valid)
  );
  
  always @(posedge clk) begin
    if (!rst_n) 
      addr_out <= {ADDR{1'b0}};
    else 
      addr_out <= encoded_addr;
  end
endmodule

module manchester_carry_encoder #(parameter WIDTH=8, ADDR=3)(
  input [WIDTH-1:0] req_in,
  output [ADDR-1:0] addr_out,
  output valid
);
  // Generate and propagate signals for Manchester carry chain
  wire [WIDTH-1:0] gen_signals;
  wire [WIDTH-1:0] prop_signals;
  wire [WIDTH:0] carry_chain;
  
  // Initialize the generate and propagate signals
  assign gen_signals = req_in;
  assign prop_signals = ~req_in;
  
  // Initialize the carry chain
  assign carry_chain[0] = 1'b0;
  
  // Build the Manchester carry chain
  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin : carry_stages
      assign carry_chain[i+1] = gen_signals[i] | (prop_signals[i] & carry_chain[i]);
    end
  endgenerate
  
  // Priority detection using carry chain
  wire [WIDTH-1:0] priority_signals;
  
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin : priority_detection
      assign priority_signals[i] = gen_signals[i] & ~carry_chain[i];
    end
  endgenerate
  
  // Encode the result
  reg [ADDR-1:0] addr_calc;
  
  integer k;
  always @(*) begin
    addr_calc = {ADDR{1'b0}};
    for (k = 0; k < WIDTH; k = k + 1) begin
      if (priority_signals[k]) 
        addr_calc = k[ADDR-1:0];
    end
  end
  
  assign addr_out = addr_calc;
  assign valid = |req_in;
endmodule