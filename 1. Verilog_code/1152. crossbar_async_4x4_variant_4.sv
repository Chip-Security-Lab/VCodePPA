//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// Title       : 4x4 Asynchronous Crossbar Switch with Hierarchical Structure
// Design      : crossbar_async_4x4
// Standard    : IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

// Top-level module
module crossbar_async_4x4 (
    input  wire [7:0] data_in_0, data_in_1, data_in_2, data_in_3,
    input  wire [1:0] select_out_0, select_out_1, select_out_2, select_out_3,
    output wire [7:0] data_out_0, data_out_1, data_out_2, data_out_3
);
    // Input stage - buffer and organize input data
    wire [7:0] buffered_inputs [0:3];
    
    input_stage input_buffer (
        .data_in_0(data_in_0),
        .data_in_1(data_in_1),
        .data_in_2(data_in_2),
        .data_in_3(data_in_3),
        .buffered_out_0(buffered_inputs[0]),
        .buffered_out_1(buffered_inputs[1]),
        .buffered_out_2(buffered_inputs[2]),
        .buffered_out_3(buffered_inputs[3])
    );
    
    // Output stage - route data from inputs to outputs based on select signals
    output_stage output_router (
        .input_array(buffered_inputs),
        .select_out_0(select_out_0),
        .select_out_1(select_out_1),
        .select_out_2(select_out_2),
        .select_out_3(select_out_3),
        .data_out_0(data_out_0),
        .data_out_1(data_out_1),
        .data_out_2(data_out_2),
        .data_out_3(data_out_3)
    );
    
endmodule

// Input stage module - organizes and buffers input data
module input_stage (
    input  wire [7:0] data_in_0, data_in_1, data_in_2, data_in_3,
    output wire [7:0] buffered_out_0, buffered_out_1, buffered_out_2, buffered_out_3
);
    // Parameter for data width
    localparam DATA_WIDTH = 8;
    
    // Buffer the inputs to improve timing
    assign buffered_out_0 = data_in_0;
    assign buffered_out_1 = data_in_1;
    assign buffered_out_2 = data_in_2;
    assign buffered_out_3 = data_in_3;
    
endmodule

// Output stage module - routes data from inputs to outputs based on select signals
module output_stage (
    input  wire [7:0] input_array [0:3],
    input  wire [1:0] select_out_0, select_out_1, select_out_2, select_out_3,
    output wire [7:0] data_out_0, data_out_1, data_out_2, data_out_3
);
    // Instantiate individual mux modules for each output
    mux_8bit_4to1 mux_out0 (
        .data_inputs(input_array),
        .select(select_out_0),
        .data_out(data_out_0)
    );
    
    mux_8bit_4to1 mux_out1 (
        .data_inputs(input_array),
        .select(select_out_1),
        .data_out(data_out_1)
    );
    
    mux_8bit_4to1 mux_out2 (
        .data_inputs(input_array),
        .select(select_out_2),
        .data_out(data_out_2)
    );
    
    mux_8bit_4to1 mux_out3 (
        .data_inputs(input_array),
        .select(select_out_3),
        .data_out(data_out_3)
    );
    
endmodule

// 8-bit 4-to-1 multiplexer module
module mux_8bit_4to1 (
    input  wire [7:0] data_inputs [0:3],
    input  wire [1:0] select,
    output wire [7:0] data_out
);
    // Parameter for data width
    localparam DATA_WIDTH = 8;
    
    // Implement 4-to-1 multiplexer functionality
    assign data_out = data_inputs[select];
    
endmodule