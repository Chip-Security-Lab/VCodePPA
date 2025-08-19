module caesar_cipher #(parameter SHIFT = 3, CHARSET = 26) (
    input wire clk, enable,
    input wire [7:0] char_in,
    output reg [7:0] cipher_out
);
    wire [7:0] char_offset;
    wire [7:0] shifted_char;
    
    // Handle only lowercase ASCII letters 'a' to 'z'
    assign char_offset = (char_in >= 8'h61 && char_in <= 8'h7A) ? (char_in - 8'h61) : 8'h0;
    assign shifted_char = ((char_offset + SHIFT) % CHARSET) + 8'h61;
    
    always @(posedge clk) begin
        if (enable) begin
            if (char_in >= 8'h61 && char_in <= 8'h7A)
                cipher_out <= shifted_char;
            else
                cipher_out <= char_in;  // Non-alphabetic characters unchanged
        end
    end
endmodule