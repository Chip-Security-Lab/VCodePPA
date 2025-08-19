//SystemVerilog
// Top level module
module AsyncLatch #(parameter WIDTH=4) (
    input en,
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);

    // Internal signals
    wire [WIDTH-1:0] latched_data;
    
    // Data latching submodule
    DataLatch #(.WIDTH(WIDTH)) data_latch (
        .en(en),
        .data_in(data_in),
        .data_out(latched_data)
    );
    
    // Output buffer submodule
    OutputBuffer #(.WIDTH(WIDTH)) output_buffer (
        .data_in(latched_data),
        .data_out(data_out)
    );

endmodule

// Data latching submodule
module DataLatch #(parameter WIDTH=4) (
    input en,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    always @* if(en) data_out = data_in;
endmodule

// Output buffer submodule
module OutputBuffer #(parameter WIDTH=4) (
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    always @* data_out = data_in;
endmodule