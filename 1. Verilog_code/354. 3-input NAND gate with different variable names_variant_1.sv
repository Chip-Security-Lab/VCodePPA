//SystemVerilog
///////////////////////////////////////////////////////////
// Module: nand3_2
// Description: Top-level module for 3-input NAND gate with optimized architecture
///////////////////////////////////////////////////////////
module nand3_2 #(
    parameter PIPELINE_STAGE = 0  // Parameterized design for flexibility
) (
    input  wire X,
    input  wire Y,
    input  wire Z,
    output wire F
);

    generate
        if (PIPELINE_STAGE == 1) begin: pipelined_impl
            // Pipelined implementation for better timing
            nand3_pipelined nand3_impl (
                .in_x(X),
                .in_y(Y),
                .in_z(Z),
                .out_f(F)
            );
        end else begin: direct_impl
            // Direct implementation for lower latency
            nand3_direct nand3_impl (
                .in_x(X),
                .in_y(Y),
                .in_z(Z),
                .out_f(F)
            );
        end
    endgenerate
    
endmodule

///////////////////////////////////////////////////////////
// Module: nand3_direct
// Description: Direct implementation of 3-input NAND function
///////////////////////////////////////////////////////////
module nand3_direct (
    input  wire in_x,
    input  wire in_y,
    input  wire in_z,
    output wire out_f
);
    
    // Optimized direct NAND implementation
    assign out_f = ~(in_x & in_y & in_z);
    
endmodule

///////////////////////////////////////////////////////////
// Module: nand3_pipelined
// Description: Pipelined implementation for better timing
///////////////////////////////////////////////////////////
module nand3_pipelined (
    input  wire in_x,
    input  wire in_y,
    input  wire in_z,
    output wire out_f
);
    
    wire and_stage_result;
    
    // Implement AND function
    logical_and3 and_stage (
        .in_a(in_x),
        .in_b(in_y),
        .in_c(in_z),
        .out_result(and_stage_result)
    );
    
    // Implement NOT function
    logical_inverter inv_stage (
        .in_value(and_stage_result),
        .out_value(out_f)
    );
    
endmodule

///////////////////////////////////////////////////////////
// Module: logical_and3
// Description: Optimized 3-input AND function implementation
///////////////////////////////////////////////////////////
module logical_and3 (
    input  wire in_a,
    input  wire in_b,
    input  wire in_c,
    output wire out_result
);
    
    assign out_result = in_a & in_b & in_c;
    
endmodule

///////////////////////////////////////////////////////////
// Module: logical_inverter
// Description: Optimized inverter implementation
///////////////////////////////////////////////////////////
module logical_inverter (
    input  wire in_value,
    output wire out_value
);
    
    assign out_value = ~in_value;
    
endmodule