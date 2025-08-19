//SystemVerilog
// IEEE 1364-2005 Verilog standard
// Top-level module
module prio_enc_comb_valid #(parameter W=8, A=3)(
  input [W-1:0] requests,
  output [A-1:0] encoded_addr,
  output valid
);
  
  wire [W-1:0] one_hot_priority;
  wire valid_internal;
  
  // Instantiate priority detection module
  priority_detector #(
    .WIDTH(W)
  ) priority_det_inst (
    .requests(requests),
    .one_hot_priority(one_hot_priority),
    .valid(valid_internal)
  );
  
  // Instantiate address encoder module
  address_encoder #(
    .WIDTH(W),
    .ADDR_WIDTH(A)
  ) addr_enc_inst (
    .one_hot_priority(one_hot_priority),
    .valid(valid_internal),
    .encoded_addr(encoded_addr),
    .valid_out(valid)
  );
  
endmodule

// Module for detecting highest priority request
module priority_detector #(parameter WIDTH=8)(
  input [WIDTH-1:0] requests,
  output [WIDTH-1:0] one_hot_priority,
  output valid
);
  
  wire [WIDTH-1:0] has_higher_priority;
  
  // Detect if any request is active
  assign valid = |requests;
  
  // Generate higher priority indicator signals
  assign has_higher_priority[0] = 1'b0;
  
  genvar j;
  generate
    for (j = 1; j < WIDTH; j = j + 1) begin: gen_prefix
      assign has_higher_priority[j] = has_higher_priority[j-1] | requests[j-1];
    end
  endgenerate
  
  // Generate one-hot priority signal
  generate
    for (j = 0; j < WIDTH; j = j + 1) begin: gen_one_hot
      assign one_hot_priority[j] = requests[j] & ~has_higher_priority[j];
    end
  endgenerate
  
endmodule

// Module for encoding the priority address
module address_encoder #(parameter WIDTH=8, ADDR_WIDTH=3)(
  input [WIDTH-1:0] one_hot_priority,
  input valid,
  output reg [ADDR_WIDTH-1:0] encoded_addr,
  output reg valid_out
);
  
  // Priority encoder logic
  always @(*) begin
    encoded_addr = {ADDR_WIDTH{1'b0}};
    valid_out = valid;
    
    // Parallel encoding logic
    for (integer i = 0; i < WIDTH; i = i + 1) begin
      if (one_hot_priority[i]) begin
        encoded_addr = i[ADDR_WIDTH-1:0];
      end
    end
  end
  
endmodule