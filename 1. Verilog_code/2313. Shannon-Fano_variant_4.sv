//SystemVerilog
//=============================================================================
// Top-level module for Shannon-Fano encoder with pipelined architecture
//=============================================================================
module shannon_fano_encoder (
    input         clk,           // Clock input (added for pipelining)
    input         rst_n,         // Reset input (added for proper sequencing)
    input  [3:0]  symbol,        // Input symbol to encode
    input         enable,        // Enable signal
    output [7:0]  code,          // Output encoded symbol
    output [2:0]  code_length    // Length of the encoded symbol
);
    // Pipeline stage registers
    reg          enable_stage1, enable_stage2;
    reg  [3:0]   symbol_stage1;
    reg  [7:0]   symbol_code_stage1, symbol_code_stage2;
    reg  [2:0]   symbol_length_stage1, symbol_length_stage2;
    
    // Internal connections
    wire [7:0]   symbol_code_lookup;
    wire [2:0]   symbol_length_lookup;
    
    // Stage 1: Symbol registration and lookup initiation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            symbol_stage1  <= 4'b0;
            enable_stage1  <= 1'b0;
        end else begin
            symbol_stage1  <= symbol;
            enable_stage1  <= enable;
        end
    end
    
    // Code lookup table instance - optimized for timing
    code_lookup_table code_table_inst (
        .clk          (clk),
        .symbol       (symbol_stage1),
        .symbol_code  (symbol_code_lookup),
        .symbol_length(symbol_length_lookup)
    );
    
    // Stage 2: Register lookup results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            symbol_code_stage1   <= 8'b0;
            symbol_length_stage1 <= 3'b0;
            enable_stage2        <= 1'b0;
        end else begin
            symbol_code_stage1   <= symbol_code_lookup;
            symbol_length_stage1 <= symbol_length_lookup;
            enable_stage2        <= enable_stage1;
        end
    end
    
    // Stage 3: Prepare for output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            symbol_code_stage2   <= 8'b0;
            symbol_length_stage2 <= 3'b0;
        end else begin
            symbol_code_stage2   <= symbol_code_stage1;
            symbol_length_stage2 <= symbol_length_stage1;
        end
    end
    
    // Output controller - final stage with output gating
    output_controller output_ctrl_inst (
        .enable        (enable_stage2),
        .symbol_code   (symbol_code_stage2),
        .symbol_length (symbol_length_stage2),
        .code          (code),
        .code_length   (code_length)
    );
    
endmodule

//=============================================================================
// Code lookup table module - stores pre-computed codes and lengths
// Synchronized design with registered outputs for improved timing
//=============================================================================
module code_lookup_table (
    input         clk,           // Clock input for registered outputs
    input  [3:0]  symbol,        // Input symbol
    output reg [7:0] symbol_code,    // Output code (registered)
    output reg [2:0] symbol_length   // Output length (registered)
);
    // Memory arrays to store codes and lengths
    reg [7:0] code_memory [0:15];
    reg [2:0] length_memory [0:15];
    
    // Initialize the lookup tables
    initial begin
        // Symbol 0 (most common)
        code_memory[0] = 8'b0;         length_memory[0] = 3'd1;
        // Symbol 1-2 (common)
        code_memory[1] = 8'b10;        length_memory[1] = 3'd2;
        code_memory[2] = 8'b11;        length_memory[2] = 3'd2;
        // Symbol 3-6 (less common)
        code_memory[3] = 8'b100;       length_memory[3] = 3'd3;
        code_memory[4] = 8'b101;       length_memory[4] = 3'd3;
        code_memory[5] = 8'b110;       length_memory[5] = 3'd3;
        code_memory[6] = 8'b111;       length_memory[6] = 3'd3;
        // Symbol 7-15 (rare)
        code_memory[7] = 8'b1000;      length_memory[7] = 3'd4;
        code_memory[8] = 8'b1001;      length_memory[8] = 3'd4;
        code_memory[9] = 8'b1010;      length_memory[9] = 3'd4;
        code_memory[10] = 8'b1011;     length_memory[10] = 3'd4;
        code_memory[11] = 8'b1100;     length_memory[11] = 3'd4;
        code_memory[12] = 8'b1101;     length_memory[12] = 3'd4;
        code_memory[13] = 8'b1110;     length_memory[13] = 3'd4;
        code_memory[14] = 8'b1111;     length_memory[14] = 3'd4;
        code_memory[15] = 8'b10000;    length_memory[15] = 3'd5;
    end
    
    // Registered memory lookup for improved timing
    // This creates a 1-cycle latency but improves clock frequency
    always @(posedge clk) begin
        symbol_code <= code_memory[symbol];
        symbol_length <= length_memory[symbol];
    end
    
endmodule

//=============================================================================
// Output controller module - handles enable gating with optimized structure
//=============================================================================
module output_controller (
    input         enable,        // Enable signal
    input  [7:0]  symbol_code,   // Symbol code from pipeline
    input  [2:0]  symbol_length, // Symbol length from pipeline
    output [7:0]  code,          // Final encoded output
    output [2:0]  code_length    // Final length output
);
    // Enable-gated outputs with explicit bit-width management
    assign code = enable ? symbol_code : 8'b0;
    assign code_length = enable ? symbol_length : 3'b0;
    
endmodule