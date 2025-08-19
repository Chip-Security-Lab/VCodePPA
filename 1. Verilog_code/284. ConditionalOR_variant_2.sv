//SystemVerilog
// Top level module
module ConditionalOR(
    input cond,
    input [7:0] mask, data,
    output [7:0] result
);
    // Internal wires
    wire [7:0] masked_data;
    wire [7:0] original_data;
    wire [7:0] mux_result;
    
    // Instantiate submodules
    BitwiseORUnit or_unit (
        .data_in(data),
        .mask(mask),
        .data_out(masked_data)
    );
    
    DataPassthrough passthrough (
        .data_in(data),
        .data_out(original_data)
    );
    
    DataSelector selector (
        .select(cond),
        .data_a(masked_data),
        .data_b(original_data),
        .result(mux_result)
    );
    
    // Output register for better timing
    OutputRegister output_reg (
        .data_in(mux_result),
        .data_out(result)
    );
endmodule

// Submodule for bitwise OR operation
module BitwiseORUnit #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] mask,
    output [WIDTH-1:0] data_out
);
    assign data_out = data_in | mask;
endmodule

// Submodule for passing through original data
module DataPassthrough #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);
    assign data_out = data_in;
endmodule

// Submodule for selecting between two data paths
module DataSelector #(
    parameter WIDTH = 8
)(
    input select,
    input [WIDTH-1:0] data_a,
    input [WIDTH-1:0] data_b,
    output [WIDTH-1:0] result
);
    assign result = select ? data_a : data_b;
endmodule

// Output register module
module OutputRegister #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    always @(*) begin
        data_out = data_in;
    end
endmodule