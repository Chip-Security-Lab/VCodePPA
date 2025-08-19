//SystemVerilog
module shannon_fano_encoder (
    input        clk,         // Added clock signal for valid sequential logic
    input        rst_n,       // Added reset signal
    input  [3:0] symbol,
    input        ready,       // Ready signal from receiver (replaces ack)
    output       valid,       // Valid signal to receiver (replaces req)
    output [7:0] code,
    output [2:0] code_length
);
    // Pre-computed codes and lengths - would normally be generated
    reg [7:0] codes [0:15];
    reg [2:0] lengths [0:15];
    
    // Internal registers for valid signal and data
    reg        valid_reg;
    reg [7:0]  code_reg;
    reg [2:0]  length_reg;
    reg [3:0]  symbol_reg;
    reg        data_loaded;
    
    initial begin
        // Symbol 0 (most common)
        codes[0] = 8'b0;        lengths[0] = 1;
        // Symbol 1-2 (common)
        codes[1] = 8'b10;       lengths[1] = 2;
        codes[2] = 8'b11;       lengths[2] = 2;
        // Symbol 3-6 (less common)
        codes[3] = 8'b100;      lengths[3] = 3;
        codes[4] = 8'b101;      lengths[4] = 3;
        codes[5] = 8'b110;      lengths[5] = 3;
        codes[6] = 8'b111;      lengths[6] = 3;
        // And so on with remaining symbols
        // ...
        
        // Initialize signals
        valid_reg = 1'b0;
        data_loaded = 1'b0;
    end
    
    // Valid-Ready handshake logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_reg <= 1'b0;
            data_loaded <= 1'b0;
            symbol_reg <= 4'b0;
        end
        else begin
            // New data is available but not yet validated
            if (!data_loaded && !valid_reg) begin
                symbol_reg <= symbol;
                data_loaded <= 1'b1;
            end
            
            // Set valid when data is loaded
            if (data_loaded && !valid_reg) begin
                valid_reg <= 1'b1;
                code_reg <= codes[symbol_reg];
                length_reg <= lengths[symbol_reg];
            end
            
            // Clear valid when handshake completes
            if (valid_reg && ready) begin
                valid_reg <= 1'b0;
                data_loaded <= 1'b0;
            end
        end
    end
    
    // Output assignments
    assign valid = valid_reg;
    assign code = valid_reg ? code_reg : 8'b0;
    assign code_length = valid_reg ? length_reg : 3'b0;
    
endmodule