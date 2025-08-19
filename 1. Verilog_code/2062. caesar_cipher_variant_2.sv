//SystemVerilog
module caesar_cipher #(
    parameter SHIFT = 3, 
    parameter CHARSET = 26
) (
    input wire clk, 
    input wire enable,
    input wire [7:0] char_in,
    output reg [7:0] cipher_out
);

    reg [7:0] char_in_reg;
    reg enable_reg;
    reg is_lowercase_reg;
    reg [7:0] char_offset_reg;
    reg [7:0] shifted_char_reg;

    ////////////////////////////////////////////////////////////////////////////////
    // Input Register Stage: Register input character and enable
    ////////////////////////////////////////////////////////////////////////////////
    always @(posedge clk) begin
        char_in_reg <= char_in;
        enable_reg  <= enable;
    end

    ////////////////////////////////////////////////////////////////////////////////
    // Character Type Detection Stage: Register if input is lowercase
    ////////////////////////////////////////////////////////////////////////////////
    always @(posedge clk) begin
        if (char_in >= 8'h61 && char_in <= 8'h7A)
            is_lowercase_reg <= 1'b1;
        else
            is_lowercase_reg <= 1'b0;
    end

    ////////////////////////////////////////////////////////////////////////////////
    // Character Offset Calculation: Calculate offset from 'a' if lowercase
    ////////////////////////////////////////////////////////////////////////////////
    always @(posedge clk) begin
        if (is_lowercase_reg)
            char_offset_reg <= char_in_reg - 8'h61;
        else
            char_offset_reg <= 8'h0;
    end

    ////////////////////////////////////////////////////////////////////////////////
    // Caesar Shift Calculation: Perform Caesar cipher shift for lowercase
    ////////////////////////////////////////////////////////////////////////////////
    always @(posedge clk) begin
        shifted_char_reg <= ((char_offset_reg + SHIFT) % CHARSET) + 8'h61;
    end

    ////////////////////////////////////////////////////////////////////////////////
    // Output Register Stage: Output ciphered char or original char
    ////////////////////////////////////////////////////////////////////////////////
    always @(posedge clk) begin
        if (enable_reg) begin
            if (is_lowercase_reg)
                cipher_out <= shifted_char_reg;
            else
                cipher_out <= char_in_reg;
        end
    end

endmodule