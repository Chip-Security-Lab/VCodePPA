//SystemVerilog
//-----------------------------------------------------------------------------
// Project: Error Detection Decoder
// Module:  error_detect_decoder (Top Level)
// Description: Top level module that instantiates validation and decoder units
// Standard: IEEE 1364-2005
//-----------------------------------------------------------------------------
module error_detect_decoder #(
    parameter ADDR_WIDTH = 2,
    parameter SEL_WIDTH = 4
)(
    input [ADDR_WIDTH-1:0] addr,
    input valid,
    output [SEL_WIDTH-1:0] select,
    output error
);
    
    // Internal signals
    wire is_valid;
    wire [SEL_WIDTH-1:0] decoder_out;
    
    // Validation unit checks if the input is valid
    validation_unit u_validation (
        .valid_in(valid),
        .is_valid(is_valid),
        .error(error)
    );
    
    // Decoder unit converts address to one-hot encoding
    decoder_unit #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .SEL_WIDTH(SEL_WIDTH)
    ) u_decoder (
        .addr(addr),
        .is_valid(is_valid),
        .select(decoder_out)
    );
    
    // Output selection logic
    output_selector u_selector (
        .decoder_out(decoder_out),
        .select(select)
    );
    
endmodule

//-----------------------------------------------------------------------------
// Module:  validation_unit
// Description: Validates input signal and generates error flag
//-----------------------------------------------------------------------------
module validation_unit (
    input valid_in,
    output is_valid,
    output reg error
);
    
    // Pass through valid signal directly
    assign is_valid = valid_in;
    
    // Generate error signal when input is invalid
    always @(*) begin
        error = ~valid_in;
    end
    
endmodule

//-----------------------------------------------------------------------------
// Module:  decoder_unit
// Description: Decodes address input to one-hot encoding when valid
//-----------------------------------------------------------------------------
module decoder_unit #(
    parameter ADDR_WIDTH = 2,
    parameter SEL_WIDTH = 4
)(
    input [ADDR_WIDTH-1:0] addr,
    input is_valid,
    output reg [SEL_WIDTH-1:0] select
);
    
    // Address to one-hot decoder with enable (valid signal)
    always @(*) begin
        select = {SEL_WIDTH{1'b0}};
        
        if (is_valid) begin
            select[addr] = 1'b1;
        end
    end
    
endmodule

//-----------------------------------------------------------------------------
// Module:  output_selector
// Description: Selects and forwards the decoder output
//-----------------------------------------------------------------------------
module output_selector (
    input [3:0] decoder_out,
    output [3:0] select
);
    
    // Direct connection for now, but could be expanded with additional logic
    assign select = decoder_out;
    
endmodule