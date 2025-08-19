//SystemVerilog
module adaptive_huffman #(
    parameter MAX_SYMBOLS = 16,
    parameter SYMBOL_WIDTH = 8
)(
    input                      clock,
    input                      reset,
    input [SYMBOL_WIDTH-1:0]   symbol_in,
    input                      symbol_valid,
    output reg [31:0]          code_out,
    output reg [5:0]           length_out,
    output reg                 code_valid
);
    // Use localparam for better readability and optimization
    localparam SYMBOL_INDEX_WIDTH = 4;
    
    reg [7:0] symbol_count [0:MAX_SYMBOLS-1];
    wire [SYMBOL_INDEX_WIDTH-1:0] symbol_index = symbol_in[SYMBOL_INDEX_WIDTH-1:0];
    
    // Optimize reset logic with separate always block
    integer i;
    always @(posedge clock) begin
        if (reset) begin
            for (i = 0; i < MAX_SYMBOLS; i = i + 1)
                symbol_count[i] <= 8'b0;
        end else if (symbol_valid) begin
            // Update symbol frequency with direct indexing
            symbol_count[symbol_index] <= symbol_count[symbol_index] + 8'b1;
        end
    end
    
    // Separate code generation logic for better timing
    always @(posedge clock) begin
        if (reset) begin
            code_valid <= 1'b0;
            code_out <= 32'b0;
            length_out <= 6'b0;
        end else if (symbol_valid) begin
            // Generate codes using priority-optimized case statement
            case (symbol_index)
                4'h0: begin 
                    code_out <= 32'h0; 
                    length_out <= 6'd1; 
                end
                4'h1: begin 
                    code_out <= 32'h2; 
                    length_out <= 6'd2; 
                end
                // ... other symbols ...
                default: begin 
                    code_out <= 32'h3; 
                    length_out <= 6'd2; 
                end
            endcase
            
            code_valid <= 1'b1;
        end else begin
            code_valid <= 1'b0;
        end
    end
    
    // IEEE 1364-2005 Verilog standard compliant
endmodule