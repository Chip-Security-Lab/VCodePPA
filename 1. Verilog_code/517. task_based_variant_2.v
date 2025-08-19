// Top level module
module task_based(
    input [3:0] in,
    output [1:0] out
);

    // Instantiate processing module
    process_unit process_inst(
        .in(in),
        .out(out)
    );

endmodule

// Processing unit module
module process_unit(
    input [3:0] in,
    output [1:0] out
);
    // Process input bits
    assign out = {in[3], ^in[2:0]};

endmodule