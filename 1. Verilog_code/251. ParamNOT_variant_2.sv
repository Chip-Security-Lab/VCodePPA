//SystemVerilog
// SystemVerilog
// Submodule performing bitwise NOT operation
module NotOperationSubmodule #(parameter WIDTH = 8) (
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);
    // Performs bitwise NOT operation on the input data
    assign data_out = ~data_in;
endmodule

// Top module instantiating the NotOperation submodule
module TopModuleParamNOT #(parameter WIDTH = 8) (
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);

    // Instantiate the NotOperation submodule
    NotOperationSubmodule #(
        .WIDTH(WIDTH)
    ) i_not_operation (
        .data_in(data_in),
        .data_out(data_out)
    );

endmodule