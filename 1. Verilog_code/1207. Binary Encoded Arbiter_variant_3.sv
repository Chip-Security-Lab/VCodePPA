//SystemVerilog
module binary_encoded_arbiter #(parameter WIDTH=4) (
  input clk, reset_n,
  input [WIDTH-1:0] req_i,
  output reg [$clog2(WIDTH)-1:0] sel_o,
  output reg valid_o
);
  // Register input requests to reduce input timing path
  reg [WIDTH-1:0] req_r;
  
  // Pre-compute valid signal in first stage
  reg valid_pre;
  
  // Internal signals for carry-look-ahead logic
  wire [WIDTH-1:0] priority_mask;
  wire [WIDTH-1:0] isolated_req;
  wire [$clog2(WIDTH)-1:0] encoded_priority;
  
  // First stage register - capture inputs
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      req_r <= 0;
      valid_pre <= 0;
    end else begin
      req_r <= req_i;
      valid_pre <= |req_i;
    end
  end
  
  // Carry-look-ahead priority masking in combinational logic
  generate
    genvar i;
    assign priority_mask[0] = 1'b1;
    for (i = 1; i < WIDTH; i = i + 1) begin : gen_priority_mask
      assign priority_mask[i] = priority_mask[i-1] & ~req_r[i-1];
    end
  endgenerate
  
  // Isolate the highest priority request using carry-look-ahead principle
  assign isolated_req = req_r & priority_mask;
  
  // Encoder using carry-look-ahead for faster encoding
  carry_lookahead_encoder #(.WIDTH(WIDTH)) encoder_inst (
    .req_i(isolated_req),
    .encoded_o(encoded_priority)
  );
  
  // Register final outputs with reset
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      sel_o <= 0;
      valid_o <= 0;
    end else begin
      sel_o <= encoded_priority;
      valid_o <= valid_pre;
    end
  end
endmodule

// Carry-look-ahead encoder module
module carry_lookahead_encoder #(parameter WIDTH=4) (
  input [WIDTH-1:0] req_i,
  output [$clog2(WIDTH)-1:0] encoded_o
);
  // Direct implementation of carry-look-ahead encoding without intermediate registers
  wire [$clog2(WIDTH)-1:0] result;
  
  generate
    genvar j, i;
    for (j = 0; j < $clog2(WIDTH); j = j + 1) begin : gen_encoder_bits
      wire [WIDTH-1:0] bit_contrib;
      
      for (i = 0; i < WIDTH; i = i + 1) begin : gen_bit_contrib
        assign bit_contrib[i] = ((i >> j) & 1) & req_i[i];
      end
      
      assign result[j] = |bit_contrib;
    end
  endgenerate
  
  assign encoded_o = result;
endmodule