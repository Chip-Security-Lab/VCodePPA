//SystemVerilog
module mipi_cphy_serializer #(parameter WIDTH = 16) (
  input wire clk, reset_n,
  input wire [WIDTH-1:0] data_in,
  input wire valid_in,
  output wire [2:0] trio_out, // 3-wire interface for C-PHY
  output reg ready_out
);

  // Registered inputs to reduce input path delay
  reg [WIDTH-1:0] data_in_r;
  reg valid_in_r;

  // Internal state registers
  reg [WIDTH-1:0] buffer;
  reg [5:0] count;
  reg [2:0] symbol;

  // Block 1: Input Registering
  // Registers data_in and valid_in on clock edge
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      data_in_r <= {WIDTH{1'b0}};
      valid_in_r <= 1'b0;
    end else begin
      data_in_r <= data_in;
      valid_in_r <= valid_in;
    end
  end

  // Add encode_symbol implementation
  function automatic [2:0] encode_symbol;
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

  // Block 2: Data Buffer Register
  // Loads new data when available and ready
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      buffer <= {WIDTH{1'b0}};
    end else if (valid_in_r && ready_out) begin
      buffer <= data_in_r;
    end
  end

  // Block 3: Count Register
  // Manages the serialization count
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      count <= 6'd0;
    end else if (valid_in_r && ready_out) begin
      count <= 6'd0; // Reset count when new data is loaded
    end else if (!ready_out) begin
      count <= count + 3; // Increment count during serialization
    end
  end

  // Block 4: Symbol Register
  // Updates the output symbol during serialization
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      symbol <= 3'b000;
    end else if (!ready_out) begin
      // Extract current 3 bits and encode as symbol
      // Need to ensure count + 3 does not exceed WIDTH before accessing buffer
      // The original logic checks (count + 3) >= (WIDTH - 3) to end,
      // meaning the last access is buffer[WIDTH-6 +: 3] or similar.
      // The maximum value of count before the last access is WIDTH - 6.
      // The access is buffer[count +: 3]. If count is WIDTH - 6, this is buffer[WIDTH-6 : WIDTH-4].
      // If count is WIDTH - 3, this would be buffer[WIDTH-3 : WIDTH-1].
      // The condition (count + 3) >= (WIDTH - 3) means the next count will be >= WIDTH - 3.
      // So the current count is < WIDTH - 3.
      // The last valid count for access is when count + 3 < WIDTH.
      // The access is buffer[count +: 3]. This means indices count, count+1, count+2 are accessed.
      // The highest index is count + 2. This must be < WIDTH. So count < WIDTH - 2.
      // Let's review the original logic:
      // count <= count + 3;
      // if ((count + 3) >= (WIDTH - 3)) ready_out <= 1'b1;
      // This means the check for ready_out happens *after* count is updated.
      // The symbol update happens *before* count is updated in the original block.
      // symbol <= encode_symbol(buffer[count+:3]);
      // count <= count + 3;
      // if ((count + 3) >= (WIDTH - 3)) ready_out <= 1'b1;
      // This implies the symbol is based on the *current* count before increment.
      // The next ready_out state is based on the *next* count value.
      // So, symbol update depends on current count, ready_out depends on next count.

      // Let's re-align the symbol update logic with the original intent:
      // The symbol is based on buffer[current_count +: 3]
      // The count update is count <= current_count + 3
      // The ready_out update is based on (current_count + 3) >= (WIDTH - 3)
      // The symbol update should happen when !ready_out is active.
      // Need to ensure the access buffer[count +: 3] is valid.
      // The original code implies count will not exceed WIDTH-3 when accessing buffer.
      // The condition (count + 3) >= (WIDTH-3) triggers ready_out=1.
      // This means the last symbol is generated when count is such that (count + 3) is just below WIDTH-3,
      // or exactly WIDTH-3?
      // If WIDTH=16, (count + 3) >= 13.
      // If count=0, 3 < 13. symbol=b[0+:3], count=3.
      // If count=3, 6 < 13. symbol=b[3+:3], count=6.
      // If count=6, 9 < 13. symbol=b[6+:3], count=9.
      // If count=9, 12 < 13. symbol=b[9+:3], count=12.
      // If count=12, 15 >= 13. symbol=b[12+:3], count=15. ready_out=1.
      // The last access is buffer[12+:3], which is buffer[12], buffer[13], buffer[14]. This is valid for WIDTH=16.
      // So the symbol update should happen when !ready_out is true.
      symbol <= encode_symbol(buffer[count+:3]);
    end
  end

  // Block 5: Ready Output Register
  // Controls when the module is ready for new data
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      ready_out <= 1'b1;
    end else if (valid_in_r && ready_out) begin
      ready_out <= 1'b0; // Not ready while processing new data
    end else if (!ready_out) begin
      // Check if serialization is complete based on the NEXT count value
      if ((count + 3) >= (WIDTH - 3)) begin
        ready_out <= 1'b1; // Ready when serialization finishes
      end
      // else ready_out remains 0
    end
  end

  // Output is directly from the symbol register
  assign trio_out = symbol;

endmodule