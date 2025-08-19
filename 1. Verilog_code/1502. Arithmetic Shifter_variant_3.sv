//SystemVerilog
// IEEE 1364-2005 Verilog standard
///////////////////////////////////////////////////////////////////////////////
// Top-level module: arith_shifter
///////////////////////////////////////////////////////////////////////////////
module arith_shifter #(
    parameter WIDTH = 8
) (
    input  wire             clk,
    input  wire             rst,
    input  wire             shift_en,
    input  wire [WIDTH-1:0] data_in,
    input  wire [2:0]       shift_amt,
    output wire [WIDTH-1:0] result
);
    // Internal signals
    wire [WIDTH-1:0] shift_result;
    
    // Shift operation submodule with optimized conditional inverted subtractor
    shift_operation #(
        .WIDTH(WIDTH)
    ) shift_op_inst (
        .data_in   (data_in),
        .shift_amt (shift_amt),
        .result    (shift_result)
    );
    
    // Register control submodule
    register_control #(
        .WIDTH(WIDTH)
    ) reg_ctrl_inst (
        .clk          (clk),
        .rst          (rst),
        .enable       (shift_en),
        .data_in      (shift_result),
        .data_out     (result)
    );
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// Submodule: shift_operation - Handles the arithmetic shift operation
///////////////////////////////////////////////////////////////////////////////
module shift_operation #(
    parameter WIDTH = 8
) (
    input  wire [WIDTH-1:0] data_in,
    input  wire [2:0]       shift_amt,
    output wire [WIDTH-1:0] result
);
    // Internal signals for optimized conditional inverted subtractor
    wire [2:0] inverted_shift_amt;
    wire [2:0] actual_shift_amt;
    wire invert_flag;
    
    // Determine whether to invert the operand
    assign invert_flag = shift_amt[2];
    
    // Conditional invert of operand
    assign inverted_shift_amt = ~shift_amt + 1'b1;
    
    // Select between original and inverted based on flag
    assign actual_shift_amt = invert_flag ? inverted_shift_amt : shift_amt;
    
    // Perform shift operation with conditional inversion
    wire [WIDTH-1:0] shift_temp;
    assign shift_temp = $signed(data_in) >>> actual_shift_amt[1:0];
    
    // Final result with conditional adjustment
    assign result = invert_flag ? {WIDTH{shift_temp[WIDTH-1]}} : shift_temp;
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// Submodule: register_control - Handles register updates with control signals
///////////////////////////////////////////////////////////////////////////////
module register_control #(
    parameter WIDTH = 8
) (
    input  wire             clk,
    input  wire             rst,
    input  wire             enable,
    input  wire [WIDTH-1:0] data_in,
    output reg  [WIDTH-1:0] data_out
);
    // Register with reset and enable
    always @(posedge clk) begin
        if (rst)
            data_out <= {WIDTH{1'b0}};
        else if (enable)
            data_out <= data_in;
    end
    
endmodule