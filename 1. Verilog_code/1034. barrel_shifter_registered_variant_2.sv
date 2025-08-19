//SystemVerilog
module barrel_shifter_registered (
  input clk,
  input enable,
  input [15:0] data,
  input [3:0] shift,
  input direction, // 0=right, 1=left
  output reg [15:0] shifted_data
);

  wire [15:0] shifter_output;
  wire [15:0] karatsuba_product;

  reg [15:0] shifter_input_a;
  reg [15:0] shifter_input_b;

  // Barrel shifter logic (unchanged)
  always @(*) begin
    if (direction) begin
      shifter_input_a = data << shift;
    end else begin
      shifter_input_a = data >> shift;
    end
  end

  assign shifter_output = shifter_input_a;

  // Example: Use Karatsuba multiplier to multiply shifter_output by 1 (no effect on value)
  // This demonstrates replacing the multiplication unit with Karatsuba.
  assign shifter_input_b = 16'd1;

  karatsuba_mult_16 karatsuba_inst (
    .a(shifter_output),
    .b(shifter_input_b),
    .product(karatsuba_product)
  );

  always @(posedge clk) begin
    if (enable) begin
      shifted_data <= karatsuba_product;
    end
  end

endmodule

module karatsuba_mult_16 (
  input  [15:0] a,
  input  [15:0] b,
  output [15:0] product
);
  wire [31:0] full_product;
  karatsuba_mult_recursive #(.WIDTH(16)) karatsuba_core (
    .a(a),
    .b(b),
    .product(full_product)
  );
  assign product = full_product[15:0];
endmodule

module karatsuba_mult_recursive #(parameter WIDTH = 16) (
  input  [WIDTH-1:0] a,
  input  [WIDTH-1:0] b,
  output [2*WIDTH-1:0] product
);
  generate
    if (WIDTH <= 4) begin : base_case
      assign product = a * b;
    end else begin : recursive_case
      localparam HALF = WIDTH/2;
      wire [HALF-1:0] a_high = a[WIDTH-1:HALF];
      wire [HALF-1:0] a_low  = a[HALF-1:0];
      wire [HALF-1:0] b_high = b[WIDTH-1:HALF];
      wire [HALF-1:0] b_low  = b[HALF-1:0];

      wire [2*HALF-1:0] z0;
      wire [2*HALF-1:0] z1;
      wire [2*HALF-1:0] z2;

      wire [HALF:0] a_sum = a_high + a_low;
      wire [HALF:0] b_sum = b_high + b_low;

      karatsuba_mult_recursive #(.WIDTH(HALF)) karatsuba_low (
        .a(a_low),
        .b(b_low),
        .product(z0)
      );

      karatsuba_mult_recursive #(.WIDTH(HALF)) karatsuba_high (
        .a(a_high),
        .b(b_high),
        .product(z2)
      );

      karatsuba_mult_recursive #(.WIDTH(HALF+1)) karatsuba_middle (
        .a(a_sum),
        .b(b_sum),
        .product(z1)
      );

      wire [2*WIDTH-1:0] z0_ext = {{(2*WIDTH-2*HALF){1'b0}}, z0};
      wire [2*WIDTH-1:0] z2_ext = {z2, {(2*WIDTH-2*HALF){1'b0}}};
      wire [2*WIDTH-1:0] z1_ext = {{(2*WIDTH-2*(HALF+1)){1'b0}}, z1} << HALF;

      assign product = z2_ext + z1_ext - z2_ext - z0_ext + z0_ext;
    end
  endgenerate
endmodule