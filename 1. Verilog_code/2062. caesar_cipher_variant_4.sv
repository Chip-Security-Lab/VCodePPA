//SystemVerilog
module caesar_cipher #(parameter SHIFT = 3, CHARSET = 26) (
    input wire clk,
    input wire enable,
    input wire [7:0] char_in,
    output reg [7:0] cipher_out
);

    // Pipeline registers
    reg        is_lowercase_stage1, is_lowercase_stage2;
    reg [7:0]  char_offset_stage1, char_offset_stage2;
    reg [7:0]  char_in_stage1, char_in_stage2;
    reg [7:0]  shifted_char_stage2;

    // ----------- Pipeline Stage 1: Predecode -----------
    // Precompute is_lowercase and char_offset in parallel
    wire char_ge_61 = (char_in[7:5] == 3'b011) && (char_in[4:0] >= 5'h01); // >= 8'h61
    wire char_le_7A = (char_in[7:5] == 3'b011) && (char_in[4:0] <= 5'h1A); // <= 8'h7A
    wire is_lowercase_wire = char_ge_61 & char_le_7A;
    wire [7:0] char_offset_wire = char_in - 8'h61;

    always @(posedge clk) begin
        if (enable) begin
            is_lowercase_stage1  <= is_lowercase_wire;
            char_offset_stage1   <= char_offset_wire;
            char_in_stage1       <= char_in;
        end
    end

    // ----------- Pipeline Stage 2: Shift and Modulo -----------
    // Parallel calculation and registration
    wire [7:0] char_offset_mod = (char_offset_stage1 + SHIFT) >= CHARSET ?
                                 (char_offset_stage1 + SHIFT - CHARSET) :
                                 (char_offset_stage1 + SHIFT);
    wire [7:0] shifted_char_wire = char_offset_mod + 8'h61;

    always @(posedge clk) begin
        if (enable) begin
            is_lowercase_stage2    <= is_lowercase_stage1;
            char_in_stage2         <= char_in_stage1;
            shifted_char_stage2    <= shifted_char_wire;
        end
    end

    // ----------- Pipeline Stage 3: Output Mux -----------
    always @(posedge clk) begin
        if (enable) begin
            cipher_out <= (is_lowercase_stage2) ? shifted_char_stage2 : char_in_stage2;
        end
    end

endmodule