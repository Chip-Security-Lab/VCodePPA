//SystemVerilog
module huffman_encoder (
    input [7:0] symbol_in,
    input       valid_in,       // Valid signal (replaces req_in)
    output reg [15:0] code_out,
    output reg [3:0]  code_len,
    output reg       ready_out  // Ready signal (replaces ack_out)
);
    // Internal signals
    reg [15:0] next_code;
    reg [3:0]  next_len;
    
    // Generate code and length based on input symbol
    always @(*) begin
        if (valid_in) begin
            case (symbol_in)
                8'h41: begin next_code = 16'b0; next_len = 4'd1; end        // 'A'
                8'h42: begin next_code = 16'b10; next_len = 4'd2; end       // 'B'
                8'h43: begin next_code = 16'b110; next_len = 4'd3; end      // 'C'
                8'h44: begin next_code = 16'b1110; next_len = 4'd4; end     // 'D'
                8'h45: begin next_code = 16'b11110; next_len = 4'd5; end    // 'E'
                default: begin next_code = 16'b111110; next_len = 4'd6; end // Others
            endcase
            ready_out = 1'b1; // Ready to accept data when valid is active
        end else begin
            next_code = 16'b0;
            next_len = 4'd0;
            ready_out = 1'b0; // Not ready when input is not valid
        end
        
        // Drive outputs
        code_out = next_code;
        code_len = next_len;
    end
endmodule