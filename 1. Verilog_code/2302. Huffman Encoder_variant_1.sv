//SystemVerilog
module huffman_encoder (
    input wire        clk,          // Clock input
    input wire        rst_n,        // Reset input
    input wire [7:0]  symbol_in,    // Input symbol to encode
    input wire        enable,       // Enable signal
    output reg [15:0] code_out,     // Output Huffman code
    output reg [3:0]  code_len      // Length of the output code
);

    // Symbol to code mapping - moved from sequential to combinational logic
    reg [15:0] symbol_to_code;
    reg [3:0]  symbol_to_len;
    
    // Pipeline stage registers with improved placement
    reg [7:0]  symbol_reg;
    reg        enable_pipe1, enable_pipe2;
    reg [15:0] code_pipe1, code_pipe2;
    reg [3:0]  len_pipe1, len_pipe2;
    
    // Combinational mapping logic - moved before registers for retiming
    always @(*) begin
        case (symbol_in)
            8'h41: begin symbol_to_code = 16'b0;      symbol_to_len = 4'd1; end // 'A'
            8'h42: begin symbol_to_code = 16'b10;     symbol_to_len = 4'd2; end // 'B'
            8'h43: begin symbol_to_code = 16'b110;    symbol_to_len = 4'd3; end // 'C'
            8'h44: begin symbol_to_code = 16'b1110;   symbol_to_len = 4'd4; end // 'D'
            8'h45: begin symbol_to_code = 16'b11110;  symbol_to_len = 4'd5; end // 'E'
            default: begin symbol_to_code = 16'b111110; symbol_to_len = 4'd6; end // Others
        endcase
    end

    // Pipeline stage 1 - Register the combinational logic results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            symbol_reg <= 8'b0;
            enable_pipe1 <= 1'b0;
            code_pipe1 <= 16'b0;
            len_pipe1 <= 4'b0;
        end else begin
            symbol_reg <= symbol_in;
            enable_pipe1 <= enable;
            
            if (enable) begin
                code_pipe1 <= symbol_to_code;
                len_pipe1 <= symbol_to_len;
            end else begin
                code_pipe1 <= 16'b0;
                len_pipe1 <= 4'b0;
            end
        end
    end

    // Pipeline stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code_pipe2 <= 16'b0;
            len_pipe2 <= 4'b0;
            enable_pipe2 <= 1'b0;
        end else begin
            code_pipe2 <= code_pipe1;
            len_pipe2 <= len_pipe1;
            enable_pipe2 <= enable_pipe1;
        end
    end

    // Final output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code_out <= 16'b0;
            code_len <= 4'b0;
        end else begin
            if (enable_pipe2) begin
                code_out <= code_pipe2;
                code_len <= len_pipe2;
            end else begin
                code_out <= 16'b0;
                code_len <= 4'b0;
            end
        end
    end

endmodule