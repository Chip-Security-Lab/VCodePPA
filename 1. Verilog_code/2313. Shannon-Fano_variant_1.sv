//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// Top-level Shannon-Fano Encoder Module
///////////////////////////////////////////////////////////////////////////////
module shannon_fano_encoder #(
    parameter SYMBOL_WIDTH = 4,
    parameter CODE_WIDTH = 8,
    parameter LENGTH_WIDTH = 3
)(
    input  logic [SYMBOL_WIDTH-1:0] symbol,
    input  logic                    enable,
    output logic [CODE_WIDTH-1:0]   code,
    output logic [LENGTH_WIDTH-1:0] code_length
);
    // Internal connections
    logic [CODE_WIDTH-1:0]   symbol_code;
    logic [LENGTH_WIDTH-1:0] symbol_length;
    
    // Encode module to generate Shannon-Fano codes
    shannon_fano_encoder_core #(
        .SYMBOL_WIDTH(SYMBOL_WIDTH),
        .CODE_WIDTH(CODE_WIDTH),
        .LENGTH_WIDTH(LENGTH_WIDTH)
    ) encoder_core_inst (
        .symbol       (symbol),
        .code         (symbol_code),
        .code_length  (symbol_length)
    );
    
    // Output control module
    shannon_fano_output_control #(
        .CODE_WIDTH(CODE_WIDTH),
        .LENGTH_WIDTH(LENGTH_WIDTH)
    ) output_control_inst (
        .enable       (enable),
        .symbol_code  (symbol_code),
        .symbol_length(symbol_length),
        .code         (code),
        .code_length  (code_length)
    );
endmodule

///////////////////////////////////////////////////////////////////////////////
// Shannon-Fano Encoder Core Module
///////////////////////////////////////////////////////////////////////////////
module shannon_fano_encoder_core #(
    parameter SYMBOL_WIDTH = 4,
    parameter CODE_WIDTH = 8,
    parameter LENGTH_WIDTH = 3
)(
    input  logic [SYMBOL_WIDTH-1:0] symbol,
    output logic [CODE_WIDTH-1:0]   code,
    output logic [LENGTH_WIDTH-1:0] code_length
);
    // Lookup table component
    shannon_fano_code_table #(
        .SYMBOL_WIDTH(SYMBOL_WIDTH),
        .CODE_WIDTH(CODE_WIDTH),
        .LENGTH_WIDTH(LENGTH_WIDTH)
    ) code_table_inst (
        .symbol      (symbol),
        .code        (code),
        .code_length (code_length)
    );
endmodule

///////////////////////////////////////////////////////////////////////////////
// Shannon-Fano Code Table Module
///////////////////////////////////////////////////////////////////////////////
module shannon_fano_code_table #(
    parameter SYMBOL_WIDTH = 4,
    parameter CODE_WIDTH = 8,
    parameter LENGTH_WIDTH = 3,
    parameter TABLE_SIZE = 1 << SYMBOL_WIDTH
)(
    input  logic [SYMBOL_WIDTH-1:0] symbol,
    output logic [CODE_WIDTH-1:0]   code,
    output logic [LENGTH_WIDTH-1:0] code_length
);
    // Pre-computed tables
    logic [CODE_WIDTH-1:0]   codes   [0:TABLE_SIZE-1];
    logic [LENGTH_WIDTH-1:0] lengths [0:TABLE_SIZE-1];
    
    // Initialize lookup tables
    initial begin
        // High probability symbols (shorter codes)
        codes[0] = 8'b0;        lengths[0] = 1;
        
        // Medium probability symbols
        codes[1] = 8'b10;       lengths[1] = 2;
        codes[2] = 8'b11;       lengths[2] = 2;
        
        // Lower probability symbols
        codes[3] = 8'b100;      lengths[3] = 3;
        codes[4] = 8'b101;      lengths[4] = 3;
        codes[5] = 8'b110;      lengths[5] = 3;
        codes[6] = 8'b111;      lengths[6] = 3;
        
        // Remaining symbols with default values
        for (int i = 7; i < TABLE_SIZE; i++) begin
            codes[i] = 0;
            lengths[i] = 0;
        end
    end
    
    // Table lookup logic
    assign code = codes[symbol];
    assign code_length = lengths[symbol];
endmodule

///////////////////////////////////////////////////////////////////////////////
// Output Control Module
///////////////////////////////////////////////////////////////////////////////
module shannon_fano_output_control #(
    parameter CODE_WIDTH = 8,
    parameter LENGTH_WIDTH = 3
)(
    input  logic                    enable,
    input  logic [CODE_WIDTH-1:0]   symbol_code,
    input  logic [LENGTH_WIDTH-1:0] symbol_length,
    output logic [CODE_WIDTH-1:0]   code,
    output logic [LENGTH_WIDTH-1:0] code_length
);
    // Output gating based on enable signal using conditional operator
    assign code = enable ? symbol_code : {CODE_WIDTH{1'b0}};
    assign code_length = enable ? symbol_length : {LENGTH_WIDTH{1'b0}};
endmodule