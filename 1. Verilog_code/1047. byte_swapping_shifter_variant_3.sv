//SystemVerilog
// -----------------------------------------------------------------------------
// Top-Level Module: byte_swapping_shifter
// Function: Hierarchically organizes byte/word/bit swapping operations on 32-bit input
// -----------------------------------------------------------------------------
module byte_swapping_shifter (
    input  wire [31:0] data_in,
    input  wire [1:0]  swap_mode, // 00=none, 01=swap bytes, 10=swap words, 11=reverse
    output wire [31:0] data_out
);

    wire [31:0] passthrough_data;
    wire [31:0] byte_swapped_data;
    wire [31:0] word_swapped_data;
    wire [31:0] reversed_data;

    // Passthrough operation (no swap)
    passthrough_unit u_passthrough (
        .data_in(data_in),
        .data_out(passthrough_data)
    );

    // Byte swap operation
    byte_swap_unit u_byte_swap (
        .data_in(data_in),
        .data_out(byte_swapped_data)
    );

    // Word swap operation
    word_swap_unit u_word_swap (
        .data_in(data_in),
        .data_out(word_swapped_data)
    );

    // Bit reverse operation
    bit_reverse_unit u_bit_reverse (
        .data_in(data_in),
        .data_out(reversed_data)
    );

    // Swap mode selector
    swap_selector u_selector (
        .swap_mode(swap_mode),
        .passthrough_data(passthrough_data),
        .byte_swapped_data(byte_swapped_data),
        .word_swapped_data(word_swapped_data),
        .reversed_data(reversed_data),
        .data_out(data_out)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: passthrough_unit
// Function: Pass-through module (no swap)
// -----------------------------------------------------------------------------
module passthrough_unit (
    input  wire [31:0] data_in,
    output wire [31:0] data_out
);
    assign data_out = data_in;
endmodule

// -----------------------------------------------------------------------------
// Submodule: byte_swap_unit
// Function: Swaps bytes in 32-bit input
//          {byte0, byte1, byte2, byte3} -> {byte3, byte2, byte1, byte0}
// -----------------------------------------------------------------------------
module byte_swap_unit (
    input  wire [31:0] data_in,
    output wire [31:0] data_out
);
    assign data_out = {data_in[7:0], data_in[15:8], data_in[23:16], data_in[31:24]};
endmodule

// -----------------------------------------------------------------------------
// Submodule: word_swap_unit
// Function: Swaps upper and lower 16-bit words
//          {word1, word0} -> {word0, word1}
// -----------------------------------------------------------------------------
module word_swap_unit (
    input  wire [31:0] data_in,
    output wire [31:0] data_out
);
    assign data_out = {data_in[15:0], data_in[31:16]};
endmodule

// -----------------------------------------------------------------------------
// Submodule: bit_reverse_unit
// Function: Reverses bit order of 32-bit input
// Output: data_out[i] = data_in[31-i]
// -----------------------------------------------------------------------------
module bit_reverse_unit (
    input  wire [31:0] data_in,
    output wire [31:0] data_out
);
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : reverse_bits
            assign data_out[i] = data_in[31 - i];
        end
    endgenerate
endmodule

// -----------------------------------------------------------------------------
// Submodule: swap_selector
// Function: 4-to-1 multiplexer for selecting the swap operation output
// -----------------------------------------------------------------------------
module swap_selector (
    input  wire [1:0]  swap_mode,
    input  wire [31:0] passthrough_data,
    input  wire [31:0] byte_swapped_data,
    input  wire [31:0] word_swapped_data,
    input  wire [31:0] reversed_data,
    output reg  [31:0] data_out
);
    always @(*) begin
        case (swap_mode)
            2'b00: data_out = passthrough_data;
            2'b01: data_out = byte_swapped_data;
            2'b10: data_out = word_swapped_data;
            2'b11: data_out = reversed_data;
            default: data_out = passthrough_data;
        endcase
    end
endmodule