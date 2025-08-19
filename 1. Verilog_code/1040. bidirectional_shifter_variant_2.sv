//SystemVerilog
module bidirectional_shifter #(parameter DATA_W = 16) (
    input  wire [DATA_W-1:0] data,
    input  wire [$clog2(DATA_W)-1:0] amount,
    input  wire left_not_right,      // Direction control
    input  wire arithmetic_shift,    // 1=arithmetic, 0=logical
    output wire [DATA_W-1:0] result
);
    wire [DATA_W-1:0] shift_left_result;
    wire [DATA_W-1:0] shift_right_result;
    wire use_arithmetic_shift;

    assign use_arithmetic_shift = (~left_not_right) & arithmetic_shift;

    // Left shift operation
    assign shift_left_result = data << amount;

    // Optimized right shift operation: arithmetic or logical based on 'arithmetic_shift'
    assign shift_right_result = use_arithmetic_shift ?
                                $signed(data) >>> amount :
                                data >> amount;

    // Select between left shift and right shift result
    assign result = left_not_right ? shift_left_result : shift_right_result;

endmodule