//SystemVerilog
module reset_source_priority(
  input  wire pwr_fail,
  input  wire watchdog_timeout,
  input  wire manual_btn,
  input  wire brownout,
  output reg  [1:0] reset_cause,
  output wire system_reset
);
  wire [1:0] mul_a, mul_b;
  wire [3:0] karatsuba_product;
  reg  [1:0] selected_a, selected_b;

  wire is_pwr_fail;
  wire is_brownout;
  wire is_watchdog_timeout;
  wire is_manual_btn;

  assign is_pwr_fail        = pwr_fail;
  assign is_brownout        = ~is_pwr_fail        & brownout;
  assign is_watchdog_timeout= ~is_pwr_fail & ~is_brownout        & watchdog_timeout;
  assign is_manual_btn      = ~is_pwr_fail & ~is_brownout & ~is_watchdog_timeout & manual_btn;

  assign system_reset = pwr_fail | watchdog_timeout | manual_btn | brownout;

  always @(*) begin
    if (is_pwr_fail) begin
      selected_a = 2'b01;
      selected_b = 2'b00;
    end else if (is_brownout) begin
      selected_a = 2'b01;
      selected_b = 2'b01;
    end else if (is_watchdog_timeout) begin
      selected_a = 2'b01;
      selected_b = 2'b10;
    end else if (is_manual_btn) begin
      selected_a = 2'b01;
      selected_b = 2'b11;
    end else begin
      selected_a = 2'b01;
      selected_b = 2'b00;
    end
  end

  assign mul_a = selected_a;
  assign mul_b = selected_b;

  karatsuba_2bit_multiplier karatsuba_mul_inst (
    .a(mul_a),
    .b(mul_b),
    .product(karatsuba_product)
  );

  always @(*) begin
    reset_cause = karatsuba_product[1:0];
  end

endmodule

module karatsuba_2bit_multiplier(
  input  wire [1:0] a,
  input  wire [1:0] b,
  output wire [3:0] product
);
  wire a0b0;
  wire a1b1;
  wire a1_xor_a0;
  wire b1_xor_b0;
  wire mid;
  wire [3:0] prod;

  assign a0b0      = a[0] & b[0];
  assign a1b1      = a[1] & b[1];
  assign a1_xor_a0 = a[1] ^ a[0];
  assign b1_xor_b0 = b[1] ^ b[0];
  assign mid       = a1_xor_a0 & b1_xor_b0;

  assign prod[0] = a0b0;
  assign prod[1] = mid ^ a1b1;
  assign prod[2] = mid ^ a0b0;
  assign prod[3] = a1b1 & (mid ^ a0b0);

  assign product = prod;

endmodule