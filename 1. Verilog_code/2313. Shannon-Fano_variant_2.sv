//SystemVerilog
module shannon_fano_encoder (
    input  [3:0] symbol,
    input        valid,    // Replaces enable (sender indicates data valid)
    output       ready,    // New signal (receiver indicates ready to accept)
    output [7:0] code,
    output [2:0] code_length
);
    // Pre-computed codes and lengths - would normally be generated
    reg [7:0] codes [0:15];
    reg [2:0] lengths [0:15];
    
    // Internal state for handshake protocol
    reg data_accepted;
    
    // Always ready to accept new data in this implementation
    assign ready = 1'b1;
    
    // Output registers
    reg [7:0] code_reg;
    reg [2:0] code_length_reg;
    
    // Assign outputs from registers
    assign code = code_reg;
    assign code_length = code_length_reg;
    
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
        
        data_accepted = 1'b0;
        code_reg = 8'b0;
        code_length_reg = 3'b0;
    end
    
    // Valid-Ready handshake logic
    always @(valid, ready) begin
        if (valid && ready) begin
            data_accepted = 1'b1;
        end
        else begin
            data_accepted = 1'b0;
        end
    end
    
    // Output assignment based on handshake status
    always @(valid, ready, symbol) begin
        if (valid && ready) begin
            code_reg = codes[symbol];
            code_length_reg = lengths[symbol];
        end
        else begin
            code_reg = 8'b0;
            code_length_reg = 3'b0;
        end
    end
    
endmodule