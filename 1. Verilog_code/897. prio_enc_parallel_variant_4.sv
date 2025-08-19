//SystemVerilog
// IEEE 1364-2005 Verilog
// Top module - Priority Encoder with parallel implementation
module prio_enc_parallel #(
  parameter N = 16
) (
  input  wire [N-1:0]           req,
  output wire [$clog2(N)-1:0]   index
);

  // Internal signals
  wire [N-1:0] lead_one;

  // Instance of leading one detector
  leading_one_detector #(
    .WIDTH(N)
  ) u_leading_one_detector (
    .req      (req),
    .lead_one (lead_one)
  );

  // Instance of encoder
  position_encoder #(
    .N(N)
  ) u_position_encoder (
    .lead_one (lead_one),
    .index    (index)
  );

endmodule

// Leading One Detector Module
// Identifies the highest priority active bit
module leading_one_detector #(
  parameter WIDTH = 16
) (
  input  wire [WIDTH-1:0] req,
  output wire [WIDTH-1:0] lead_one
);

  // LUT-based subtractor implementation
  wire [7:0] lut_borrow; // Borrows for each bit position
  wire [WIDTH-1:0] mask;
  
  // 8-bit LUT-assisted subtraction implementation
  // Generate borrow signals using lookup tables
  assign lut_borrow[0] = req[0] ? 1'b0 : 1'b1;
  assign lut_borrow[1] = (req[1] && !lut_borrow[0]) ? 1'b0 : 1'b1;
  assign lut_borrow[2] = (req[2] && !lut_borrow[1]) ? 1'b0 : 1'b1;
  assign lut_borrow[3] = (req[3] && !lut_borrow[2]) ? 1'b0 : 1'b1;
  assign lut_borrow[4] = (req[4] && !lut_borrow[3]) ? 1'b0 : 1'b1;
  assign lut_borrow[5] = (req[5] && !lut_borrow[4]) ? 1'b0 : 1'b1;
  assign lut_borrow[6] = (req[6] && !lut_borrow[5]) ? 1'b0 : 1'b1;
  assign lut_borrow[7] = (req[7] && !lut_borrow[6]) ? 1'b0 : 1'b1;
  
  // Calculate result bits using XOR with borrow
  // For 8-bit implementation
  generate
    genvar i;
    for(i = 0; i < 8 && i < WIDTH; i = i + 1) begin : gen_sub_bits_lower
      assign mask[i] = req[i] ^ (i == 0 ? 1'b1 : lut_borrow[i-1]);
    end
    
    // For bits beyond 8 (if WIDTH > 8), use standard subtraction
    for(i = 8; i < WIDTH; i = i + 1) begin : gen_sub_bits_upper
      assign mask[i] = req[i] ^ (i == 0 ? 1'b1 : 
                               ((i < 8) ? lut_borrow[i-1] : 
                                ((req[i-1:0] == {i{1'b0}}) ? 1'b1 : 1'b0)));
    end
  endgenerate
  
  // Isolate the highest priority bit
  assign lead_one = req & ~mask;

endmodule

// Position Encoder Module
// Converts one-hot encoded leading one to binary index
module position_encoder #(
  parameter N = 16
) (
  input  wire [N-1:0]           lead_one,
  output reg  [$clog2(N)-1:0]   index
);

  integer i;
  
  always @(*) begin
    index = {$clog2(N){1'b0}}; // Initialize with zeros
    for (i = 0; i < N; i = i+1) begin
      if (lead_one[i]) begin
        index = i[$clog2(N)-1:0];
      end
    end
  end

endmodule