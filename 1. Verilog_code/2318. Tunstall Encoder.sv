module tunstall_encoder #(
    parameter CODEWORD_WIDTH = 4
)(
    input             clk_i,
    input             enable_i,
    input             rst_i,
    input      [7:0]  data_i,
    input             data_valid_i,
    output reg [CODEWORD_WIDTH-1:0] code_o,
    output reg        code_valid_o
);
    // Simplified Tunstall implementation with predefined dictionary
    reg [7:0] buffer;
    reg       buffer_valid;
    
    always @(posedge clk_i) begin
        if (rst_i) begin
            buffer <= 0;
            buffer_valid <= 0;
            code_valid_o <= 0;
        end else if (enable_i) begin
            if (data_valid_i) begin
                if (!buffer_valid) begin
                    buffer <= data_i;
                    buffer_valid <= 1;
                    code_valid_o <= 0;
                end else begin
                    // Map two bytes to one codeword (simplified)
                    case ({buffer[1:0], data_i[1:0]})
                        4'b0000: code_o <= 4'h0;
                        4'b0001: code_o <= 4'h1;
                        // ... other combinations ...
                        default: code_o <= 4'hF;
                    endcase
                    
                    buffer <= 0;
                    buffer_valid <= 0;
                    code_valid_o <= 1;
                end
            end
        end else begin
            code_valid_o <= 0;
        end
    end
endmodule