//SystemVerilog
// Top-level module - Optimized for better PPA
module ParamOR #(parameter WIDTH=8) (
    input [WIDTH-1:0] in1, in2,
    output [WIDTH-1:0] result
);
    // Direct connection to the operation module, removing unnecessary modules
    BitwiseOperator #(
        .WIDTH(WIDTH),
        .OPERATION("OR")
    ) or_operator (
        .in1(in1),
        .in2(in2),
        .result(result)
    );
endmodule

// Optimized bitwise operation module with simplified logic
module BitwiseOperator #(
    parameter WIDTH=8,
    parameter OPERATION="OR"
) (
    input [WIDTH-1:0] in1, in2,
    output [WIDTH-1:0] result
);
    // Generate-based implementation for better synthesis results
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: bit_ops
            case(OPERATION)
                "OR":  assign result[i] = in1[i] | in2[i];
                "AND": assign result[i] = in1[i] & in2[i];
                "XOR": assign result[i] = in1[i] ^ in2[i];
                default: assign result[i] = in1[i] | in2[i];
            endcase
        end
    endgenerate
endmodule