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
    
    // Symbol index for current input with registered copies
    wire [3:0] symbol_idx = symbol_in[3:0];
    reg [3:0] symbol_idx_buf1, symbol_idx_buf2;
    
    // Pre-compute the updated symbol count
    wire [7:0] updated_count = symbol_count[symbol_idx] + 1'b1;
    
    // Counter variable with buffered copies
    integer i;
    reg [4:0] i_buf1, i_buf2;
    
    // Huffman code lookup table to replace if-else chain
    reg [31:0] h0 [0:15];
    reg [5:0] h1 [0:15];
    
    // Buffered copies of symbol_count for different logic paths
    reg [7:0] symbol_count_buf1 [0:MAX_SYMBOLS-1];
    reg [7:0] symbol_count_buf2 [0:MAX_SYMBOLS-1];
    
    // Buffer registers for h0 table
    reg [31:0] h0_buf1 [0:7];
    reg [31:0] h0_buf2 [0:7];
    reg [31:0] h0_buf3 [0:15];
    
    always @(posedge clock) begin
        // Register symbol_idx to reduce fan-out
        symbol_idx_buf1 <= symbol_idx;
        symbol_idx_buf2 <= symbol_idx;
        
        // Create multiple buffered copies of the high fan-out counters
        for (i = 0; i < MAX_SYMBOLS; i = i + 1) begin
            symbol_count_buf1[i] <= symbol_count[i];
            symbol_count_buf2[i] <= symbol_count[i];
        end
        
        // Buffer the h0 table to reduce fan-out
        for (i = 0; i < 8; i = i + 1) begin
            h0_buf1[i] <= h0[i];
            h0_buf2[i] <= h0[i+8];
        end
        
        // Create a complete buffered copy of h0
        for (i = 0; i < 16; i = i + 1) begin
            h0_buf3[i] <= h0[i];
        end
    end
    
    always @(posedge clock) begin
        if (reset) begin
            for (i = 0; i < MAX_SYMBOLS; i = i + 1)
                symbol_count[i] <= 8'h0;
            
            // Initialize Huffman code lookup tables
            h0[0] <= 32'h0;    h1[0] <= 6'h1;
            h0[1] <= 32'h2;    h1[1] <= 6'h2;
            h0[2] <= 32'h6;    h1[2] <= 6'h3;
            h0[3] <= 32'he;    h1[3] <= 6'h4;
            h0[4] <= 32'h1e;   h1[4] <= 6'h5;
            h0[5] <= 32'h3e;   h1[5] <= 6'h6;
            h0[6] <= 32'h7e;   h1[6] <= 6'h7;
            h0[7] <= 32'hfe;   h1[7] <= 6'h8;
            h0[8] <= 32'h1fe;  h1[8] <= 6'h9;
            h0[9] <= 32'h3fe;  h1[9] <= 6'ha;
            h0[10] <= 32'h7fe; h1[10] <= 6'hb;
            h0[11] <= 32'hffe; h1[11] <= 6'hc;
            h0[12] <= 32'h1ffe; h1[12] <= 6'hd;
            h0[13] <= 32'h3ffe; h1[13] <= 6'he;
            h0[14] <= 32'h7ffe; h1[14] <= 6'hf;
            h0[15] <= 32'hfffe; h1[15] <= 6'h10;
            
            code_valid <= 1'b0;
            code_out <= 32'h0;
            length_out <= 6'h0;
            i_buf1 <= 5'h0;
            i_buf2 <= 5'h0;
        end 
        else if (symbol_valid) begin
            // Update symbol frequency - only the relevant counter
            symbol_count[symbol_idx] <= updated_count;
            
            // Use the lookup table instead of if-else chain
            code_out <= (symbol_idx < 4'h10) ? h0_buf3[symbol_idx] : 32'h3;
            length_out <= (symbol_idx < 4'h10) ? h1[symbol_idx] : 6'h2;
            
            code_valid <= 1'b1;
        end
        else begin
            code_valid <= 1'b0;
        end
    end
    
    // Buffer i counter for different operations
    always @(posedge clock) begin
        i_buf1 <= i;
        i_buf2 <= i_buf1;
    end
    
endmodule