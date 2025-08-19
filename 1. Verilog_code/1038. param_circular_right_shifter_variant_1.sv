//SystemVerilog
module param_circular_right_shifter #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] data,
    input  [$clog2(WIDTH)-1:0] rotate,
    output [WIDTH-1:0] result
);

    reg [WIDTH-1:0] rotated_data;
    reg [2:0] rotate_amt_7bit;
    reg [2:0] complement_rotate_amt;
    reg [2:0] negated_rotate_amt;
    reg [2:0] add_one;
    reg [2:0] twos_complement_rotate_amt;
    reg [WIDTH-1:0] right_shifted;
    reg [WIDTH-1:0] left_shifted;
    reg [WIDTH-1:0] left_shifted_amt;

    // 仅支持7位旋转
    // 计算rotate的二进制补码（7位减法器）
    always @(*) begin
        rotate_amt_7bit = rotate[2:0];
        complement_rotate_amt = ~rotate_amt_7bit;
        add_one = 3'b001;
        negated_rotate_amt = complement_rotate_amt + add_one;
        twos_complement_rotate_amt = negated_rotate_amt;

        // 右移
        right_shifted = data >> rotate_amt_7bit;
        // 左移
        left_shifted_amt = twos_complement_rotate_amt[2:0];
        left_shifted = data << left_shifted_amt;
        // 合成循环右移
        rotated_data = right_shifted | left_shifted;
    end

    assign result = rotated_data;

endmodule