//SystemVerilog
module shift_right_logic #(parameter WIDTH=8) (
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [2:0] shift_amount,
    output reg [WIDTH-1:0] data_out
);

    wire [2:0] shift_diff;

    // 3-bit Two's Complement Subtractor
    twos_complement_subtractor_3bit u_twos_complement_subtractor (
        .minuend(shift_amount),
        .subtrahend(3'd0),
        .difference(shift_diff)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= {WIDTH{1'b0}};
        else
            data_out <= data_in >> shift_diff;
    end

endmodule

// 3-bit Two's Complement Subtractor
module twos_complement_subtractor_3bit (
    input  [2:0] minuend,
    input  [2:0] subtrahend,
    output [2:0] difference
);

    wire [2:0] subtrahend_inverted;
    wire [2:0] sum;
    wire carry_0, carry_1, carry_2;

    assign subtrahend_inverted = ~subtrahend;

    // Full adder for LSB
    assign {carry_0, sum[0]} = minuend[0] + subtrahend_inverted[0] + 1'b1;

    // Full adder for bit 1
    assign {carry_1, sum[1]} = minuend[1] + subtrahend_inverted[1] + carry_0;

    // Full adder for bit 2
    assign {carry_2, sum[2]} = minuend[2] + subtrahend_inverted[2] + carry_1;

    assign difference = sum;

endmodule