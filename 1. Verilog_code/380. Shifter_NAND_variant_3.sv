//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// Module: Shifter_NAND
// Description: Top-level module that performs shifting and NAND operation
///////////////////////////////////////////////////////////////////////////////
module Shifter_NAND(
    input [2:0] shift,
    input [7:0] val,
    output [7:0] res
);
    wire [7:0] shifted_mask;
    
    // Instantiate shifter module
    Barrel_Shifter shifter_inst (
        .shift_amount(shift),
        .shifted_value(shifted_mask)
    );
    
    // Instantiate logic operation module
    Logic_Unit logic_inst (
        .mask(shifted_mask),
        .input_value(val),
        .result(res)
    );
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// Module: Barrel_Shifter
// Description: Generates a shifted mask based on input shift amount using
//              barrel shifter architecture
///////////////////////////////////////////////////////////////////////////////
module Barrel_Shifter (
    input [2:0] shift_amount,
    output [7:0] shifted_value
);
    // Parameter for base mask
    parameter BASE_MASK = 8'hFF;
    
    // Intermediate signals for barrel shifter stages
    wire [7:0] stage0_out;
    wire [7:0] stage1_out;
    
    // Stage 0: Shift by 0 or 1 bit
    assign stage0_out = shift_amount[0] ? {BASE_MASK[6:0], 1'b0} : BASE_MASK;
    
    // Stage 1: Shift by 0 or 2 bits
    assign stage1_out = shift_amount[1] ? {stage0_out[5:0], 2'b00} : stage0_out;
    
    // Stage 2: Shift by 0 or 4 bits
    assign shifted_value = shift_amount[2] ? {stage1_out[3:0], 4'b0000} : stage1_out;
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// Module: Logic_Unit
// Description: Performs NAND operation between input value and mask
///////////////////////////////////////////////////////////////////////////////
module Logic_Unit (
    input [7:0] mask,
    input [7:0] input_value,
    output [7:0] result
);
    // Perform NAND operation
    assign result = ~(input_value & mask);
endmodule