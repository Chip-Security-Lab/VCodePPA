//SystemVerilog
// IEEE 1364-2005 Verilog
//==========================================================================
// Top-level Module: Barrel Shifter with Control Logic
//==========================================================================
module BarrelShifter #(
    parameter SIZE = 16,
    parameter SHIFT_WIDTH = 4
)(
    input [SIZE-1:0] din,
    input [SHIFT_WIDTH-1:0] shift,
    input en, left,
    output [SIZE-1:0] dout
);
    // Internal connections
    wire [SIZE-1:0] shift_left_result;
    wire [SIZE-1:0] shift_right_result;
    wire [SIZE-1:0] selected_result;
    
    // Left shifter submodule instantiation
    LeftShifter #(
        .SIZE(SIZE),
        .SHIFT_WIDTH(SHIFT_WIDTH)
    ) left_shifter_inst (
        .din(din),
        .shift(shift),
        .dout(shift_left_result)
    );
    
    // Right shifter submodule instantiation
    RightShifter #(
        .SIZE(SIZE),
        .SHIFT_WIDTH(SHIFT_WIDTH)
    ) right_shifter_inst (
        .din(din),
        .shift(shift),
        .dout(shift_right_result)
    );
    
    // Direction selector submodule instantiation
    DirectionSelector #(
        .SIZE(SIZE)
    ) dir_selector_inst (
        .left_result(shift_left_result),
        .right_result(shift_right_result),
        .select_left(left),
        .result(selected_result)
    );
    
    // Output enable control submodule instantiation
    OutputControl #(
        .SIZE(SIZE)
    ) out_control_inst (
        .din(selected_result),
        .en(en),
        .dout(dout)
    );
endmodule

//==========================================================================
// Submodule: Left Shifter
//==========================================================================
module LeftShifter #(
    parameter SIZE = 16,
    parameter SHIFT_WIDTH = 4
)(
    input [SIZE-1:0] din,
    input [SHIFT_WIDTH-1:0] shift,
    output reg [SIZE-1:0] dout
);
    // Perform left shift operation using always block
    always @(*) begin
        dout = din << shift;
    end
endmodule

//==========================================================================
// Submodule: Right Shifter
//==========================================================================
module RightShifter #(
    parameter SIZE = 16,
    parameter SHIFT_WIDTH = 4
)(
    input [SIZE-1:0] din,
    input [SHIFT_WIDTH-1:0] shift,
    output reg [SIZE-1:0] dout
);
    // Perform right shift operation using always block
    always @(*) begin
        dout = din >> shift;
    end
endmodule

//==========================================================================
// Submodule: Direction Selector
//==========================================================================
module DirectionSelector #(
    parameter SIZE = 16
)(
    input [SIZE-1:0] left_result,
    input [SIZE-1:0] right_result,
    input select_left,
    output reg [SIZE-1:0] result
);
    // Select between left and right shift result based on direction control
    always @(*) begin
        if (select_left) begin
            result = left_result;
        end
        else begin
            result = right_result;
        end
    end
endmodule

//==========================================================================
// Submodule: Output Control
//==========================================================================
module OutputControl #(
    parameter SIZE = 16
)(
    input [SIZE-1:0] din,
    input en,
    output reg [SIZE-1:0] dout
);
    // Control output based on enable signal
    always @(*) begin
        if (en) begin
            dout = din;
        end
        else begin
            dout = {SIZE{1'b0}};
        end
    end
endmodule