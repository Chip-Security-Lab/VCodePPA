//SystemVerilog
//============================================================
// Top-level module - Manages the logical shift operation
//============================================================
module param_logical_shift #(
    parameter WIDTH = 16,
    parameter SHIFT_W = $clog2(WIDTH)
)(
    input signed [WIDTH-1:0] din,
    input [SHIFT_W-1:0] shift,
    output signed [WIDTH-1:0] dout
);
    // Intermediate signals for module connections
    wire signed [WIDTH-1:0] shift_result;
    
    // Instantiate shift operation module
    shift_operation #(
        .WIDTH(WIDTH),
        .SHIFT_W(SHIFT_W)
    ) shift_op_inst (
        .data_in(din),
        .shift_amount(shift),
        .data_out(shift_result)
    );
    
    // Instantiate output buffer module
    output_buffer #(
        .WIDTH(WIDTH)
    ) out_buf_inst (
        .data_in(shift_result),
        .data_out(dout)
    );

endmodule

//============================================================
// Shift operation module - Handles the actual shift calculation
//============================================================
module shift_operation #(
    parameter WIDTH = 16,
    parameter SHIFT_W = $clog2(WIDTH)
)(
    input signed [WIDTH-1:0] data_in,
    input [SHIFT_W-1:0] shift_amount,
    output signed [WIDTH-1:0] data_out
);
    // Implement the arithmetic shift operation
    assign data_out = data_in <<< shift_amount;
    
endmodule

//============================================================
// Output buffer module - Handles output signal integrity
//============================================================
module output_buffer #(
    parameter WIDTH = 16
)(
    input signed [WIDTH-1:0] data_in,
    output signed [WIDTH-1:0] data_out
);
    // Pipeline register to improve timing
    reg signed [WIDTH-1:0] buffer_reg;
    
    always @(*) begin
        buffer_reg = data_in;
    end
    
    assign data_out = buffer_reg;
    
endmodule