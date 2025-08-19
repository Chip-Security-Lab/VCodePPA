//SystemVerilog
// Top-level module
module Demux_Bidirectional #(
    parameter N = 4,
    parameter DW = 8
) (
    inout [DW-1:0] io_port,
    input dir,          // 0:in, 1:out
    input [N-1:0] sel,
    output [DW-1:0] data_in,
    input [N-1:0][DW-1:0] data_out
);
    // Internal signals
    wire [DW-1:0] selected_data;

    // Direction controller module instantiation
    Direction_Controller #(
        .DW(DW)
    ) dir_ctrl (
        .io_port(io_port),
        .dir(dir),
        .data_in(data_in),
        .selected_data(selected_data)
    );

    // Output selector module instantiation
    Output_Selector #(
        .N(N),
        .DW(DW)
    ) out_sel (
        .data_out(data_out),
        .sel(sel),
        .selected_data(selected_data)
    );

endmodule

// Direction Controller module
module Direction_Controller #(
    parameter DW = 8
) (
    inout [DW-1:0] io_port,
    input dir,          // 0:in, 1:out
    output [DW-1:0] data_in,
    input [DW-1:0] selected_data
);
    // Input direction: assign io_port to data_in
    assign data_in = io_port;
    
    // Output direction: drive io_port with selected_data or high-impedance
    // Replace conditional operator with always block
    reg [DW-1:0] io_port_out;
    
    always @(*) begin
        if (dir) begin
            io_port_out = selected_data;
        end
        else begin
            io_port_out = {DW{1'bz}};
        end
    end
    
    assign io_port = io_port_out;

endmodule

// Output Selector module
module Output_Selector #(
    parameter N = 4,
    parameter DW = 8
) (
    input [N-1:0][DW-1:0] data_out,
    input [N-1:0] sel,
    output reg [DW-1:0] selected_data
);
    // Select the appropriate output data based on sel
    // Replace direct assignment with always block
    always @(*) begin
        selected_data = data_out[sel];
    end

endmodule