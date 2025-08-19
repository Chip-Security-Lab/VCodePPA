//SystemVerilog
// Top-level bidirectional shifter module (optimized)
module bidirectional_shifter #(parameter DATA_W=16) (
    input  wire [DATA_W-1:0]                data,
    input  wire [$clog2(DATA_W)-1:0]        amount,
    input  wire                             left_not_right,   // Direction control: 1=left, 0=right
    input  wire                             arithmetic_shift, // 1=arithmetic, 0=logical
    output wire [DATA_W-1:0]                result
);

    // Optimized shift result computation
    wire [DATA_W-1:0] shift_left_data;
    wire [DATA_W-1:0] shift_right_data;

    // Range-limited shift amount to avoid over-shifting
    wire [$clog2(DATA_W)-1:0] shift_amt = (amount >= DATA_W) ? {$clog2(DATA_W){1'b0}} : amount;

    // Logical left shift (if shift amount is 0, pass through)
    assign shift_left_data = (shift_amt == 0) ? data :
                             (shift_amt < DATA_W) ? (data << shift_amt) :
                             {DATA_W{1'b0}};

    // Right shift logic with optimized selection
    wire [DATA_W-1:0] right_logical_result;
    wire [DATA_W-1:0] right_arithmetic_result;

    assign right_logical_result =
        (shift_amt == 0) ? data :
        (shift_amt < DATA_W) ? (data >> shift_amt) :
        {DATA_W{1'b0}};

    assign right_arithmetic_result =
        (shift_amt == 0) ? data :
        (shift_amt < DATA_W) ? ($signed(data) >>> shift_amt) :
        {data[DATA_W-1], {DATA_W-1{data[DATA_W-1]}}}; // All sign bits if shift_amt >= DATA_W

    assign shift_right_data = arithmetic_shift ? right_arithmetic_result : right_logical_result;

    // Final result selection with optimized logic
    assign result = left_not_right ? shift_left_data : shift_right_data;

endmodule