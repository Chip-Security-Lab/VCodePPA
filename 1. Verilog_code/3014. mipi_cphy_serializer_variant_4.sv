//SystemVerilog
module mipi_cphy_serializer #(parameter WIDTH = 16) (
  input wire clk, reset_n,
  input wire [WIDTH-1:0] data_in,
  input wire valid_in,
  output wire [2:0] trio_out, // 3-wire interface for C-PHY
  output reg ready_out
);
  reg [WIDTH-1:0] buffer;
  reg [5:0] count;

  // New register to hold the *encoded* symbol value, placed after the encode logic
  // This replaces the 'unencoded_symbol_reg' and moves the register forward past the encode function.
  reg [2:0] encoded_symbol_reg;

  // Add encode_symbol implementation
  function automatic [2:0] encode_symbol; // Use automatic for potential recursion/re-entrancy safety, good practice
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
        default: encode_symbol = 3'b000; // Should not happen with 3-bit input
      endcase
    end
  endfunction

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      // Reset state
      buffer <= {WIDTH{1'b0}};
      count <= 6'd0;
      ready_out <= 1'b1;
      // Reset the encoded symbol register to the encoded value of 3'b000
      encoded_symbol_reg <= encode_symbol(3'b000); // Corresponds to the reset state of unencoded_symbol_reg
    end else begin
      // Flattened state transitions
      if (valid_in && ready_out) begin
        // State: Load new data
        buffer <= data_in;
        ready_out <= 1'b0;
        count <= 6'd0;
        // encoded_symbol_reg holds the value from the previous serialization cycle.
        // It retains its value here. The first new symbol will be processed next cycle.
      end else if (!ready_out && (count < WIDTH-3)) begin
        // State: Serialize data (mid-stream)
        // Extract current 3 bits from buffer, encode them, and register the result
        encoded_symbol_reg <= encode_symbol(buffer[count+:3]);
        count <= count + 3;
        // ready_out remains low (holds 0)
      end else if (!ready_out && (count >= WIDTH-3)) begin
        // State: Serialize data (last chunk)
        // Extract current 3 bits from buffer, encode them, and register the result
        encoded_symbol_reg <= encode_symbol(buffer[count+:3]);
        count <= count + 3;
        // ready_out goes high when the last 3 bits are *processed* for the register.
        ready_out <= 1'b1;
      end
      // If none of the above conditions are met (e.g., reset_n high, valid_in low, ready_out high),
      // all registers hold their current values.
    end
  end

  // The output 'trio_out' is now driven directly by the registered encoded symbol.
  // The 'encode_symbol' function is now combinational logic *before* the register 'encoded_symbol_reg'.
  assign trio_out = encoded_symbol_reg;

  // ready_out remains a registered output, no change needed here
  // output reg ready_out is already declared
endmodule