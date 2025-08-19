//SystemVerilog
// Top-level module
module Demux_Bidirectional #(
    parameter N  = 4,
    parameter DW = 8
)(
    inout  [DW-1:0]       io_port,
    input                 dir,      // 0:in, 1:out
    input  [N-1:0]        sel,
    output [DW-1:0]       data_in,
    input  [N-1:0][DW-1:0] data_out
);
    // Input path submodule instantiation
    Input_Path #(
        .DW(DW)
    ) u_input_path (
        .io_port (io_port),
        .data_in (data_in)
    );

    // Output path submodule instantiation
    Output_Path #(
        .N  (N),
        .DW (DW)
    ) u_output_path (
        .io_port  (io_port),
        .dir      (dir),
        .sel      (sel),
        .data_out (data_out)
    );

endmodule

// Input path module - Handles input direction logic
module Input_Path #(
    parameter DW = 8
)(
    inout  [DW-1:0] io_port,
    output [DW-1:0] data_in
);
    // Simple pass-through for input data
    assign data_in = io_port;
    
endmodule

// Output path module - Handles output direction logic and multiplexing
module Output_Path #(
    parameter N  = 4,
    parameter DW = 8
)(
    inout  [DW-1:0]       io_port,
    input                 dir,      // 0:in, 1:out
    input  [N-1:0]        sel,
    input  [N-1:0][DW-1:0] data_out
);
    wire [DW-1:0] selected_data;
    wire [DW-1:0] io_drive;
    
    // Selector submodule
    Output_Selector #(
        .N  (N),
        .DW (DW)
    ) u_output_selector (
        .sel         (sel),
        .data_out    (data_out),
        .selected_data (selected_data)
    );
    
    // Direction control submodule
    Direction_Control #(
        .DW (DW)
    ) u_direction_control (
        .dir           (dir),
        .selected_data (selected_data),
        .io_drive      (io_drive)
    );
    
    // Drive the IO port
    assign io_port = io_drive;
    
endmodule

// Output selector module - Selects the appropriate output data based on sel
module Output_Selector #(
    parameter N  = 4,
    parameter DW = 8
)(
    input  [N-1:0]        sel,
    input  [N-1:0][DW-1:0] data_out,
    output [DW-1:0]       selected_data
);
    // Select output data based on sel input
    assign selected_data = data_out[sel];
    
endmodule

// Direction control module - Controls IO direction based on dir signal
module Direction_Control #(
    parameter DW = 8
)(
    input             dir,           // 0:in, 1:out
    input  [DW-1:0]   selected_data,
    output [DW-1:0]   io_drive
);
    // Set output based on direction control
    assign io_drive = dir ? selected_data : {DW{1'bz}};
    
endmodule