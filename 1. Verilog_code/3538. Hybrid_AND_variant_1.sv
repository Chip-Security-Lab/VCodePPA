//SystemVerilog
//IEEE 1364-2005
module Hybrid_AND(
    input [1:0] ctrl,
    input [7:0] base,
    output [7:0] result
);
    wire [7:0] mask;
    
    // Instantiate the mask generator submodule
    Mask_Generator mask_gen (
        .ctrl(ctrl),
        .mask(mask)
    );
    
    // Instantiate the AND operation submodule
    AND_Operator and_op (
        .base(base),
        .mask(mask),
        .result(result)
    );
    
endmodule

// Mask generator submodule - creates the appropriate mask based on control signals
module Mask_Generator(
    input [1:0] ctrl,
    output reg [7:0] mask
);
    // Parameterized base mask value
    parameter BASE_MASK = 8'h0F;
    
    // Internal wires for mask calculation stages
    wire [7:0] initial_mask;
    wire [3:0] shift_amount;
    
    // Mask initialization submodule
    Mask_Initializer mask_init (
        .base_mask_param(BASE_MASK),
        .initial_mask(initial_mask)
    );
    
    // Shift amount calculator submodule
    Shift_Calculator shift_calc (
        .ctrl(ctrl),
        .shift_amount(shift_amount)
    );
    
    // Mask shifter submodule
    Mask_Shifter mask_shifter (
        .initial_mask(initial_mask),
        .shift_amount(shift_amount),
        .final_mask(mask)
    );
endmodule

// Initializes the mask with parameter value
module Mask_Initializer(
    input [7:0] base_mask_param,
    output [7:0] initial_mask
);
    assign initial_mask = base_mask_param;
endmodule

// Calculates the shift amount based on control signals
module Shift_Calculator(
    input [1:0] ctrl,
    output [3:0] shift_amount
);
    assign shift_amount = ctrl * 4;
endmodule

// Performs the actual mask shifting operation
module Mask_Shifter(
    input [7:0] initial_mask,
    input [3:0] shift_amount,
    output reg [7:0] final_mask
);
    always @(*) begin
        final_mask = initial_mask << shift_amount;
    end
endmodule

// AND operation submodule - performs the bitwise AND operation
module AND_Operator(
    input [7:0] base,
    input [7:0] mask,
    output [7:0] result
);
    // Perform the actual AND operation
    assign result = base & mask;
endmodule