//SystemVerilog
// Top-level module
module Masked_XNOR(
    input en_mask,
    input [3:0] mask, data,
    output [3:0] res
);
    // Internal signals
    wire [3:0] xnor_result;
    
    // Instantiate XOR operation module
    XOR_Operation xor_op (
        .data_in(data),
        .mask_in(mask),
        .xnor_out(xnor_result)
    );
    
    // Instantiate output selection module
    Output_Selector out_sel (
        .en_mask(en_mask),
        .data_in(data),
        .xnor_in(xnor_result),
        .result_out(res)
    );
endmodule

// Module for the XNOR operation
module XOR_Operation (
    input [3:0] data_in,
    input [3:0] mask_in,
    output [3:0] xnor_out
);
    // Calculate XNOR result 
    assign xnor_out = ~(data_in ^ mask_in);
endmodule

// Module for selecting the output based on en_mask
module Output_Selector (
    input en_mask,
    input [3:0] data_in,
    input [3:0] xnor_in,
    output [3:0] result_out
);
    // Select between original data and XNOR result
    assign result_out = en_mask ? xnor_in : data_in;
endmodule