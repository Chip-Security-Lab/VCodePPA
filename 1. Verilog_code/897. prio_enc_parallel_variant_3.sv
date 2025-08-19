//SystemVerilog
// IEEE 1364-2005
module prio_enc_parallel #(parameter N=16)(
  input [N-1:0] req,
  output reg [$clog2(N)-1:0] index
);
  // Generate mask using carry-skip adder for req + (~req)
  wire [N-1:0] req_inverted;
  wire [N-1:0] mask;
  
  // Invert all bits
  assign req_inverted = ~req;
  
  // Use carry-skip adder for req + req_inverted
  wire [N-1:0] sum;
  wire [N:0] carry;
  
  // Define skip signals and group size
  localparam SKIP_GROUP_SIZE = 4;
  wire [N/SKIP_GROUP_SIZE-1:0] skip;
  
  // Initial carry-in
  assign carry[0] = 1'b1; // Two's complement requires adding 1
  
  // Generate skip signals for each group
  genvar g;
  generate
    for (g = 0; g < N/SKIP_GROUP_SIZE; g = g + 1) begin : skip_gen
      wire [SKIP_GROUP_SIZE-1:0] p;
      
      genvar j;
      for (j = 0; j < SKIP_GROUP_SIZE; j = j + 1) begin : prop_gen
        assign p[j] = req[g*SKIP_GROUP_SIZE+j] | req_inverted[g*SKIP_GROUP_SIZE+j];
      end
      
      // Skip signal is high when all propagate signals in the group are high
      assign skip[g] = &p;
    end
  endgenerate
  
  // Implement carry-skip adder
  genvar i;
  generate
    for (i = 0; i < N; i = i + 1) begin : adder_gen
      // Compute sum for each bit
      assign sum[i] = req[i] ^ req_inverted[i] ^ carry[i];
      
      // Compute carry for next bit
      if (i % SKIP_GROUP_SIZE == SKIP_GROUP_SIZE-1) begin : skip_carry
        // End of a group - apply skip logic
        assign carry[i+1] = skip[i/SKIP_GROUP_SIZE] ? carry[i-SKIP_GROUP_SIZE+1] : 
                           (req[i] & req_inverted[i]) | ((req[i] | req_inverted[i]) & carry[i]);
      end
      else begin : regular_carry
        // Regular carry propagation within a group
        assign carry[i+1] = (req[i] & req_inverted[i]) | ((req[i] | req_inverted[i]) & carry[i]);
      end
    end
  endgenerate
  
  // Final mask is the sum (which equals req + (~req) + 1, which is req - 1)
  assign mask = sum;
  
  // Identify leading one position
  wire [N-1:0] lead_one = req & ~mask;

  integer k;
  always @(*) begin
    index = 0;
    k = 0;
    while (k < N) begin
      if (lead_one[k]) index = k[$clog2(N)-1:0];
      k = k + 1;
    end
  end
endmodule