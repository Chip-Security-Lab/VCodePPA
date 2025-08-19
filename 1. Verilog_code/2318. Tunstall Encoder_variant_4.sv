//SystemVerilog
module tunstall_encoder #(
    parameter CODEWORD_WIDTH = 4
)(
    input                          clk_i,
    input                          enable_i,
    input                          rst_i,
    input      [7:0]               data_i,
    input                          data_valid_i,
    output reg [CODEWORD_WIDTH-1:0] code_o,
    output reg                     code_valid_o
);
    // Simplified Tunstall implementation with predefined dictionary
    reg [7:0]  buffer;
    reg        buffer_valid;
    
    // Pre-computed codeword (moved before register)
    reg [CODEWORD_WIDTH-1:0] next_code;
    reg                      next_code_valid;
    
    // 4-bit selector for optimized mapping
    wire [3:0] pattern_key;
    assign pattern_key = {buffer[1:0], data_i[1:0]};
    
    // Optimized combinational logic with priority encoding
    always @(*) begin
        next_code = code_o;
        next_code_valid = 1'b0;
        
        if (enable_i && buffer_valid && data_valid_i) begin
            // Optimized mapping using priority logic
            casez (pattern_key)
                4'b00??: next_code = {2'b00, pattern_key[1:0]};
                4'b01??: next_code = {2'b01, pattern_key[1:0]};
                4'b10??: next_code = {2'b10, pattern_key[1:0]};
                4'b11??: next_code = {2'b11, pattern_key[1:0]};
                default: next_code = 4'hF;
            endcase
            next_code_valid = 1'b1;
        end
    end
    
    // Sequential logic with optimized control path
    always @(posedge clk_i) begin
        if (rst_i) begin
            buffer <= 8'h0;
            buffer_valid <= 1'b0;
            code_o <= {CODEWORD_WIDTH{1'b0}};
            code_valid_o <= 1'b0;
        end 
        else if (enable_i) begin
            // Optimized state transitions
            if (data_valid_i) begin
                if (!buffer_valid) begin
                    // Store first byte
                    buffer <= data_i;
                    buffer_valid <= 1'b1;
                    code_valid_o <= 1'b0;
                end 
                else begin
                    // Process second byte and generate code
                    buffer <= 8'h0;
                    buffer_valid <= 1'b0;
                    code_o <= next_code;
                    code_valid_o <= next_code_valid;
                end
            end
            else begin
                code_valid_o <= 1'b0;
            end
        end 
        else begin
            code_valid_o <= 1'b0;
        end
    end
endmodule