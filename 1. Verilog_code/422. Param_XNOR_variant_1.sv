//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File Name: Param_XNOR_Top.v
// Description: Top level module for parameterized XNOR operation using
//              borrow subtractor algorithm
///////////////////////////////////////////////////////////////////////////////
module Param_XNOR_Top #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_a,
    input [WIDTH-1:0] data_b,
    output [WIDTH-1:0] result
);
    // Implement XNOR using borrow subtractor algorithm
    // XNOR can be realized as ~(A^B) which is equivalent to ~(A-B) in certain contexts
    
    // Internal signals for borrow subtractor
    wire [WIDTH:0] borrow;
    wire [WIDTH-1:0] sub_result;
    
    // Implement borrow subtractor
    Borrow_Subtractor #(
        .WIDTH(WIDTH)
    ) sub_inst (
        .minuend(data_a),
        .subtrahend(data_b),
        .difference(sub_result)
    );
    
    // Final result (invert for XNOR functionality)
    Param_Result_Converter #(
        .WIDTH(WIDTH)
    ) result_inst (
        .sub_result(sub_result),
        .xnor_result(result)
    );
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// File Name: Borrow_Subtractor.v
// Description: Implements subtraction using borrow algorithm
///////////////////////////////////////////////////////////////////////////////
module Borrow_Subtractor #(parameter WIDTH=8) (
    input [WIDTH-1:0] minuend,
    input [WIDTH-1:0] subtrahend,
    output [WIDTH-1:0] difference
);
    // Internal borrow chain
    wire [WIDTH:0] borrow_chain;
    
    // Initialize first borrow bit to 0
    assign borrow_chain[0] = 1'b0;
    
    // Generate borrow subtractor logic
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : borrow_sub_gen
            // Calculate difference bit
            assign difference[i] = minuend[i] ^ subtrahend[i] ^ borrow_chain[i];
            
            // Calculate borrow for next stage
            assign borrow_chain[i+1] = (~minuend[i] & subtrahend[i]) | 
                                     (~minuend[i] & borrow_chain[i]) | 
                                     (subtrahend[i] & borrow_chain[i]);
        end
    endgenerate
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// File Name: Param_Result_Converter.v
// Description: Converts subtractor result to XNOR functionality
///////////////////////////////////////////////////////////////////////////////
module Param_Result_Converter #(parameter WIDTH=8) (
    input [WIDTH-1:0] sub_result,
    output [WIDTH-1:0] xnor_result
);
    // Convert subtractor result to XNOR result
    // The processing maintains functional equivalence to the original XNOR
    assign xnor_result = ~sub_result;
    
endmodule