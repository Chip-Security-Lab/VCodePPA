//SystemVerilog
// SystemVerilog

// Decoder module with optimized implementation
module decoder_2to4 (
    input  [1:0] addr,
    output [3:0] decoded
);
    // One-hot decoder implementation
    assign decoded = 4'b0001 << addr;
endmodule

// Data selector module with optimized implementation
module data_selector #(
    parameter WIDTH = 16
)(
    input  [WIDTH-1:0] data_array [0:3],
    input  [3:0]       decoded,
    output [WIDTH-1:0] selected_data
);
    // Optimized multiplexer implementation
    assign selected_data = (decoded[0] ? data_array[0] : '0) |
                          (decoded[1] ? data_array[1] : '0) |
                          (decoded[2] ? data_array[2] : '0) |
                          (decoded[3] ? data_array[3] : '0);
endmodule

// Address decoder and data selector combined module
module addr_decoder_selector #(
    parameter WIDTH = 16
)(
    input  [1:0]       addr,
    input  [WIDTH-1:0] data_array [0:3],
    output [WIDTH-1:0] selected_data
);
    wire [3:0] decoded;
    
    // Instantiate decoder
    decoder_2to4 decoder_inst (
        .addr(addr),
        .decoded(decoded)
    );
    
    // Instantiate data selector
    data_selector #(
        .WIDTH(WIDTH)
    ) selector_inst (
        .data_array(data_array),
        .decoded(decoded),
        .selected_data(selected_data)
    );
endmodule

// Top-level module with improved interface
module decoded_addr_mux #(
    parameter WIDTH = 16
)(
    input  [WIDTH-1:0] data_array [0:3],
    input  [1:0]       addr,
    output [WIDTH-1:0] selected_data
);
    // Instantiate the combined decoder and selector module
    addr_decoder_selector #(
        .WIDTH(WIDTH)
    ) addr_decoder_selector_inst (
        .addr(addr),
        .data_array(data_array),
        .selected_data(selected_data)
    );
endmodule