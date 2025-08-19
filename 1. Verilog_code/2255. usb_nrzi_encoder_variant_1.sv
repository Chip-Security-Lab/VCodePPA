//SystemVerilog

//-----------------------------------------------------------------------------
// USB NRZI Encoder Top Module
//-----------------------------------------------------------------------------
module usb_nrzi_encoder (
    input  wire clk,   // System clock
    input  wire en,    // Enable signal
    input  wire data,  // Input data to encode
    output reg  tx     // NRZI encoded output
);
    // Internal signals
    wire nrzi_bit;
    reg  last_bit;
    
    // Instantiate the NRZI encoding logic module
    nrzi_encoding_logic nrzi_logic_inst (
        .data_in      (data),
        .prev_bit     (last_bit),
        .encoded_bit  (nrzi_bit)
    );
    
    // Clock domain logic for state management
    always @(posedge clk) begin
        if (en) begin
            tx <= nrzi_bit;
            last_bit <= nrzi_bit;
        end
    end
endmodule

//-----------------------------------------------------------------------------
// NRZI Encoding Logic Module - Combinational logic for NRZI encoding
//-----------------------------------------------------------------------------
module nrzi_encoding_logic (
    input  wire data_in,    // Input data bit
    input  wire prev_bit,   // Previous encoded bit
    output wire encoded_bit // Newly encoded bit
);
    // NRZI encoding rule:
    // - If data_in is 1, output same as previous bit
    // - If data_in is 0, output inverted previous bit
    assign encoded_bit = data_in ? prev_bit : ~prev_bit;
endmodule