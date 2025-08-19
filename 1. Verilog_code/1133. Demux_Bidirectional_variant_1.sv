//SystemVerilog
// Top level module
module Demux_Bidirectional #(
    parameter N = 4,
    parameter DW = 8
)(
    inout [DW-1:0] io_port,
    input dir,          // 0:in, 1:out
    input [N-1:0] sel,
    output [DW-1:0] data_in,
    input [N-1:0][DW-1:0] data_out
);
    // Internal signals
    wire [DW-1:0] output_data;
    wire [DW-1:0] processed_data;
    wire output_enable;

    // Input handler submodule
    Input_Handler #(
        .DW(DW)
    ) input_handler_inst (
        .io_port(io_port),
        .data_in(data_in)
    );

    // Output selector submodule
    Output_Selector #(
        .N(N),
        .DW(DW)
    ) output_selector_inst (
        .sel(sel),
        .data_out(data_out),
        .output_data(output_data)
    );
    
    // New arithmetic processor with borrow-based subtractor
    Arithmetic_Processor #(
        .DW(DW)
    ) arithmetic_processor_inst (
        .data_in(output_data),
        .processed_data(processed_data)
    );

    // Direction controller submodule
    Direction_Controller #(
        .DW(DW)
    ) direction_controller_inst (
        .dir(dir),
        .output_data(processed_data),
        .io_port(io_port)
    );

endmodule

// Input handler module
module Input_Handler #(
    parameter DW = 8
)(
    inout [DW-1:0] io_port,
    output [DW-1:0] data_in
);
    // Simply pass through the io_port to data_in
    assign data_in = io_port;
endmodule

// Output selector module
module Output_Selector #(
    parameter N = 4,
    parameter DW = 8
)(
    input [N-1:0] sel,
    input [N-1:0][DW-1:0] data_out,
    output [DW-1:0] output_data
);
    // Select the appropriate data_out based on sel
    assign output_data = data_out[sel];
endmodule

// Arithmetic Processor module with borrow-based subtractor
module Arithmetic_Processor #(
    parameter DW = 8
)(
    input [DW-1:0] data_in,
    output [DW-1:0] processed_data
);
    // Constants for subtraction
    wire [DW-1:0] subtract_value = 8'h01;  // Value to subtract
    wire [DW-1:0] result;
    
    // Borrow-based subtractor implementation for 8-bit
    Borrow_Subtractor #(
        .WIDTH(DW)
    ) subtractor_inst (
        .minuend(data_in),
        .subtrahend(subtract_value),
        .difference(result)
    );
    
    // Mux to select either original or processed data
    // In this case, we'll use the processed data
    assign processed_data = result;
endmodule

// Borrow-based subtractor implementation
module Borrow_Subtractor #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] minuend,
    input [WIDTH-1:0] subtrahend,
    output [WIDTH-1:0] difference
);
    // Internal borrow signals
    wire [WIDTH:0] borrow;
    
    // Initialize borrow-in to 0
    assign borrow[0] = 1'b0;
    
    // Generate borrow chain and difference bits
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_borrow_stages
            assign difference[i] = minuend[i] ^ subtrahend[i] ^ borrow[i];
            assign borrow[i+1] = (~minuend[i] & subtrahend[i]) | 
                               (~minuend[i] & borrow[i]) | 
                               (subtrahend[i] & borrow[i]);
        end
    endgenerate
endmodule

// Direction controller module
module Direction_Controller #(
    parameter DW = 8
)(
    input dir,
    input [DW-1:0] output_data,
    inout [DW-1:0] io_port
);
    // Control io_port direction based on dir
    // When dir=1, drive io_port with output_data
    // When dir=0, set io_port to high impedance
    assign io_port = (dir) ? output_data : {DW{1'bz}};
endmodule