//SystemVerilog
module mipi_cphy_serializer #(parameter WIDTH = 16) (
  input wire clk, reset_n,
  input wire [WIDTH-1:0] data_in,
  input wire valid_in,
  output wire [2:0] trio_out, // 3-wire interface for C-PHY
  output reg ready_out
);

  // Calculate the number of 3-bit symbols in the data
  parameter NUM_SYMBOLS = (WIDTH + 2) / 3;

  // Calculate width for symbol index (0 to NUM_SYMBOLS-1)
  parameter SYMBOL_INDEX_WIDTH = (NUM_SYMBOLS <= 1) ? 1 : $clog2(NUM_SYMBOLS);

  // Calculate maximum bit index accessed: (NUM_SYMBOLS-1)*3
  parameter MAX_BIT_INDEX = (NUM_SYMBOLS == 1) ? 0 : (NUM_SYMBOLS - 1) * 3;
  // Calculate width for bit index (0 to MAX_BIT_INDEX)
  parameter BIT_INDEX_WIDTH = (MAX_BIT_INDEX == 0) ? 1 : $clog2(MAX_BIT_INDEX + 1);


  // Internal buffer to hold the data
  reg [WIDTH-1:0] buffer;

  // Counter for the current symbol index being processed
  reg [SYMBOL_INDEX_WIDTH-1:0] symbol_index;

  // Retimed register: holds the 3-bit data chunk *before* encoding
  reg [2:0] data_chunk_reg;

  // Function to encode 3-bit data into a 3-bit symbol (combinatorial)
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
        default: encode_symbol = 3'b000; // Should not happen with 3-bit input
      endcase
    end
  endfunction

  // Combinatorial calculation of the starting bit index based on symbol_index register
  wire [BIT_INDEX_WIDTH-1:0] current_bit_index_w = symbol_index * 3;

  // Combinatorial extraction of the 3-bit data chunk from the buffer
  // Assumes synthesis handles the part select near the end of the buffer correctly (e.g., zero-padding)
  wire [2:0] extracted_data_w = buffer[current_bit_index_w +: 3];


  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      buffer <= {WIDTH{1'b0}};
      symbol_index <= {SYMBOL_INDEX_WIDTH{1'b0}}; // Reset index to 0
      ready_out <= 1'b1; // Ready to accept new data
      data_chunk_reg <= 3'b000; // Reset the retimed register
    end else if (valid_in && ready_out) begin
      // Load new data and start serialization
      buffer <= data_in;
      ready_out <= 1'b0; // Not ready for new data until serialization is done
      symbol_index <= {SYMBOL_INDEX_WIDTH{1'b0}}; // Reset index to 0
      // Register the first data chunk (extracted_data_w based on new buffer and index 0)
      data_chunk_reg <= extracted_data_w;
    end else if (!ready_out) begin
      // Serializing data
      // Register the current extracted data chunk (extracted_data_w based on current symbol_index)
      data_chunk_reg <= extracted_data_w;

      // Check if this is the last symbol index BEFORE incrementing
      if (symbol_index == NUM_SYMBOLS - 1) begin
        // This is the last symbol, so we will be ready for new data next cycle
        ready_out <= 1'b1;
        // symbol_index will reset to 0 in the next cycle if valid_in is high
      end

      // Update symbol index for the next cycle (only if not the last symbol)
      // Or, update always and it resets on valid_in.
      // Let's increment always, and the index gets reset when valid_in & ready_out is true.
      symbol_index <= symbol_index + 1;
    end
  end

  // Output the current symbol by encoding the registered data chunk
  assign trio_out = encode_symbol(data_chunk_reg);

endmodule