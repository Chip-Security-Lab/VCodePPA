//SystemVerilog
// Top level module that instantiates specialized shifters
module BarrelShifter #(
    parameter SIZE = 16,
    parameter SHIFT_WIDTH = 4
)(
    input [SIZE-1:0] din,
    input [SHIFT_WIDTH-1:0] shift,
    input en, left,
    output [SIZE-1:0] dout
);
    // Internal wires
    wire [SIZE-1:0] left_shift_result;
    wire [SIZE-1:0] right_shift_result;
    wire [SIZE-1:0] shift_result;
    
    // Instantiate left shifter module
    LeftShifter #(
        .SIZE(SIZE),
        .SHIFT_WIDTH(SHIFT_WIDTH)
    ) left_shifter_inst (
        .din(din),
        .shift(shift),
        .dout(left_shift_result)
    );
    
    // Instantiate right shifter module
    RightShifter #(
        .SIZE(SIZE),
        .SHIFT_WIDTH(SHIFT_WIDTH)
    ) right_shifter_inst (
        .din(din),
        .shift(shift),
        .dout(right_shift_result)
    );
    
    // Shift direction selector module
    ShiftSelector #(
        .SIZE(SIZE)
    ) shift_selector_inst (
        .left_data(left_shift_result),
        .right_data(right_shift_result),
        .select_left(left),
        .dout(shift_result)
    );
    
    // Output enable control module
    OutputController #(
        .SIZE(SIZE)
    ) output_controller_inst (
        .din(shift_result),
        .en(en),
        .dout(dout)
    );
    
endmodule

// Left shift operation module
module LeftShifter #(
    parameter SIZE = 16,
    parameter SHIFT_WIDTH = 4
)(
    input [SIZE-1:0] din,
    input [SHIFT_WIDTH-1:0] shift,
    output [SIZE-1:0] dout
);
    assign dout = din << shift;
endmodule

// Right shift operation module
module RightShifter #(
    parameter SIZE = 16,
    parameter SHIFT_WIDTH = 4
)(
    input [SIZE-1:0] din,
    input [SHIFT_WIDTH-1:0] shift,
    output [SIZE-1:0] dout
);
    assign dout = din >> shift;
endmodule

// Shift direction selector module
module ShiftSelector #(
    parameter SIZE = 16
)(
    input [SIZE-1:0] left_data,
    input [SIZE-1:0] right_data,
    input select_left,
    output [SIZE-1:0] dout
);
    assign dout = select_left ? left_data : right_data;
endmodule

// Output enable control module
module OutputController #(
    parameter SIZE = 16
)(
    input [SIZE-1:0] din,
    input en,
    output [SIZE-1:0] dout
);
    assign dout = en ? din : {SIZE{1'b0}};
endmodule