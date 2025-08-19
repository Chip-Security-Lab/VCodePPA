//SystemVerilog
module mipi_cphy_serializer #(parameter WIDTH = 16) (
  input wire clk, reset_n,
  input wire [WIDTH-1:0] data_in,
  input wire valid_in,
  output wire [2:0] trio_out, // 3-wire interface for C-PHY
  output reg ready_out
);
  reg [WIDTH-1:0] buffer;
  reg [5:0] count; // Assuming WIDTH-3 fits within 6 bits, i.e., WIDTH <= 66
  reg [2:0] symbol_input_reg;

  // Parameters for conditional sum subtraction equivalent comparison
  // We want to check if count >= WIDTH-3
  // This is equivalent to checking if count - (WIDTH-3) >= 0
  // Or, checking the carry-out of count + (-(WIDTH-3)) using 2's complement
  localparam [5:0] TARGET_COUNT = WIDTH - 3;
  // Calculate 6-bit two's complement of TARGET_COUNT
  localparam [5:0] NEG_TARGET_COUNT = (~TARGET_COUNT) + 6'd1;

  // Add logic for conditional sum subtraction equivalent comparison
  // Perform 6-bit addition with a 7-bit result to capture carry-out
  wire [6:0] comparison_sum = {1'b0, count} + {1'b0, NEG_TARGET_COUNT};
  // The carry-out indicates if count >= TARGET_COUNT for unsigned numbers
  wire carry_out = comparison_sum[6];


  // Add encode_symbol implementation
  function [2:0] encode_symbol;
    input [2:0] data;
    begin
      case(data)
        3'b000: encode_symbol = 3'b001;
        3'b001: encode_symbol = 3'b010;
        3'b010: encode_symbol = 3'b100;
        3'b011: encode_symbol = 3'b101;
        3'b100: encode_symbol = 3'b011;
        3'b101: encode_symbol = 3'b110;
        3'b110: encode_symbol = 3'b111;
        3'b111: encode_symbol = 3'b000;
        default: encode_symbol = 3'b000;
      endcase
    end
  endfunction

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      buffer <= {WIDTH{1'b0}};
      count <= 6'd0;
      ready_out <= 1'b1;
      symbol_input_reg <= 3'b000;
    end else if (valid_in && ready_out) begin
      buffer <= data_in;
      ready_out <= 1'b0;
      count <= 6'd0;
    end else if (!ready_out) begin
      symbol_input_reg <= buffer[count+:3];
      count <= count + 3;

      // Replace original comparison (count >= WIDTH-3) with carry_out check
      if (carry_out) begin
           ready_out <= 1'b1;
      end
    end
  end

  assign trio_out = encode_symbol(symbol_input_reg);

endmodule