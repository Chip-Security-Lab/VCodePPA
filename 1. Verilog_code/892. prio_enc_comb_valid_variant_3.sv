//SystemVerilog
// IEEE 1364-2005 Verilog
// Top-level module
module prio_enc_comb_valid #(
  parameter W = 4,  // Width of request vector
  parameter A = 2   // Width of address output
)(
  input  [W-1:0] requests,
  input  [1:0] minuend,
  input  [1:0] subtrahend,
  output [1:0] difference,
  output [A-1:0] encoded_addr,
  output         valid
);

  // Internal signals
  wire [A-1:0] detected_addr;
  wire         request_detected;
  
  // Instantiate request detection module
  request_detector #(
    .WIDTH(W)
  ) req_detect_inst (
    .requests        (requests),
    .request_detected(request_detected)
  );
  
  // Instantiate priority encoding module
  priority_encoder #(
    .WIDTH(W),
    .ADDR_WIDTH(A)
  ) prio_enc_inst (
    .requests     (requests),
    .encoded_addr (detected_addr)
  );
  
  // Instantiate conditional sum subtractor
  conditional_sum_subtractor #(
    .WIDTH(2)
  ) subtractor_inst (
    .minuend(minuend),
    .subtrahend(subtrahend),
    .difference(difference)
  );
  
  // Output assignment
  assign encoded_addr = detected_addr;
  assign valid = request_detected;
  
endmodule

// Module for detecting if any request is active
module request_detector #(
  parameter WIDTH = 4
)(
  input  [WIDTH-1:0] requests,
  output             request_detected
);

  // Detect if any bit in the request vector is set
  assign request_detected = |requests;
  
endmodule

// Module for priority encoding
module priority_encoder #(
  parameter WIDTH = 4,
  parameter ADDR_WIDTH = 2
)(
  input  [WIDTH-1:0]      requests,
  output [ADDR_WIDTH-1:0] encoded_addr
);

  // Internal variable for loop
  integer i;
  reg [ADDR_WIDTH-1:0] addr;
  
  // Priority encoding logic
  always @(*) begin
    addr = {ADDR_WIDTH{1'b0}}; // Default value
    
    for (i = 0; i < WIDTH; i = i + 1) begin
      if (requests[i]) begin
        addr = i[ADDR_WIDTH-1:0];
      end
    end
  end
  
  // Output assignment
  assign encoded_addr = addr;
  
endmodule

// Module for conditional sum subtraction (2-bit)
module conditional_sum_subtractor #(
  parameter WIDTH = 2
)(
  input  [WIDTH-1:0] minuend,
  input  [WIDTH-1:0] subtrahend,
  output [WIDTH-1:0] difference
);
  // Internal signals
  wire [WIDTH-1:0] complement;
  wire [WIDTH:0] carry;
  wire [WIDTH-1:0] diff0, diff1;
  
  // Generate 1's complement of subtrahend
  assign complement = ~subtrahend;
  
  // Initialize carry for addition
  assign carry[0] = 1'b1; // Add 1 to get 2's complement
  
  // Generate two possible results for each bit position
  // diff0: assuming carry-in = 0, diff1: assuming carry-in = 1
  assign diff0[0] = minuend[0] ^ complement[0] ^ 1'b0;
  assign diff1[0] = minuend[0] ^ complement[0] ^ 1'b1;
  
  assign diff0[1] = minuend[1] ^ complement[1] ^ 1'b0;
  assign diff1[1] = minuend[1] ^ complement[1] ^ 1'b1;
  
  // Determine carry propagation
  assign carry[1] = (minuend[0] & complement[0]) | ((minuend[0] | complement[0]) & carry[0]);
  assign carry[2] = (minuend[1] & complement[1]) | ((minuend[1] | complement[1]) & carry[1]);
  
  // Select the correct result based on carry-in to each position
  assign difference[0] = carry[0] ? diff1[0] : diff0[0];
  assign difference[1] = carry[1] ? diff1[1] : diff0[1];
  
endmodule