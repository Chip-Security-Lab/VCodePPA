//SystemVerilog
module normalizer #(parameter WIDTH=16)(
    input wire [WIDTH-1:0] in_data,
    output reg [WIDTH-1:0] normalized_data,
    output reg [$clog2(WIDTH)-1:0] shift_count
);
    integer i;
    reg found;
    wire [7:0] subtrahend;
    wire [7:0] conditional_sum;
    reg [7:0] width_minus_i;
    reg [7:0] i_value;

    // 条件求和减法算法实现8位减法器
    conditional_subtractor_8bit cond_sub_inst (
        .a(WIDTH-1),
        .b(i_value),
        .diff(subtrahend)
    );

    always @* begin
        found = 1'b0;
        shift_count = {($clog2(WIDTH)){1'b0}};
        for (i = WIDTH-1; i >= 0; i = i - 1) begin
            i_value = i[7:0];
            if (!found && in_data[i]) begin
                found = 1'b1;
                width_minus_i = subtrahend;
                shift_count = width_minus_i[$clog2(WIDTH)-1:0];
            end
        end
        normalized_data = in_data << shift_count;
    end
endmodule

module conditional_subtractor_8bit(
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] diff
);
    wire [7:0] b_inverted;
    wire [7:0] sum;
    wire       carry_in;
    wire [7:0] carry;

    assign b_inverted = ~b;
    assign carry_in = 1'b1;

    assign {carry[0], sum[0]} = a[0] + b_inverted[0] + carry_in;
    assign {carry[1], sum[1]} = a[1] + b_inverted[1] + carry[0];
    assign {carry[2], sum[2]} = a[2] + b_inverted[2] + carry[1];
    assign {carry[3], sum[3]} = a[3] + b_inverted[3] + carry[2];
    assign {carry[4], sum[4]} = a[4] + b_inverted[4] + carry[3];
    assign {carry[5], sum[5]} = a[5] + b_inverted[5] + carry[4];
    assign {carry[6], sum[6]} = a[6] + b_inverted[6] + carry[5];
    assign {carry[7], sum[7]} = a[7] + b_inverted[7] + carry[6];

    assign diff = sum;
endmodule