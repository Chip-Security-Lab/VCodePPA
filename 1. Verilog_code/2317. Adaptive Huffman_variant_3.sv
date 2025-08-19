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
    // Symbol frequency counters
    reg [7:0] symbol_count [0:MAX_SYMBOLS-1];
    reg [3:0] symbol_idx;
    reg update_required;
    reg [31:0] next_code;
    reg [5:0] next_length;
    
    integer i;
    
    // Pre-compute symbol index to reduce critical path
    always @(*) begin
        symbol_idx = symbol_in[3:0];
        update_required = symbol_valid;
        
        // Prepare huffman code based on symbol - moved out of the clock process
        case (symbol_idx)
            4'h0: begin next_code = 32'h0; next_length = 6'd1; end
            4'h1: begin next_code = 32'h2; next_length = 6'd2; end
            // ... other symbols ...
            default: begin next_code = 32'h3; next_length = 6'd2; end
        endcase
    end
    
    // Sequential logic - now with reduced combinational complexity
    always @(posedge clock) begin
        if (reset) begin
            for (i = 0; i < MAX_SYMBOLS; i = i + 1)
                symbol_count[i] <= 8'b0;
            code_valid <= 1'b0;
            code_out <= 32'b0;
            length_out <= 6'b0;
        end 
        else begin
            // Default state
            code_valid <= 1'b0;
            
            if (update_required) begin
                // Update symbol frequency - separated from code generation
                symbol_count[symbol_idx] <= symbol_count[symbol_idx] + 8'b1;
                
                // Output the pre-computed code
                code_out <= next_code;
                length_out <= next_length;
                code_valid <= 1'b1;
            end
        end
    end
endmodule