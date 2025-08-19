module huffman_encoder (
    input [7:0] symbol_in,
    input       enable,
    output reg [15:0] code_out,
    output reg [3:0]  code_len
);
    always @(*) begin
        if (enable) begin
            case (symbol_in)
                8'h41: begin code_out = 16'b0; code_len = 1; end        // 'A'
                8'h42: begin code_out = 16'b10; code_len = 2; end       // 'B'
                8'h43: begin code_out = 16'b110; code_len = 3; end      // 'C'
                8'h44: begin code_out = 16'b1110; code_len = 4; end     // 'D'
                8'h45: begin code_out = 16'b11110; code_len = 5; end    // 'E'
                default: begin code_out = 16'b111110; code_len = 6; end // Others
            endcase
        end else begin
            code_out = 0;
            code_len = 0;
        end
    end
endmodule