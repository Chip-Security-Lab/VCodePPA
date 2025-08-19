//SystemVerilog
// Top-level module: shift_bidir_sync
module shift_bidir_sync #(
    parameter WIDTH=16
)(
    input                  clk,
    input                  rst,
    input                  dir, // 0:left, 1:right
    input  [WIDTH-1:0]     din,
    output reg [WIDTH-1:0] dout
);

    wire [WIDTH-1:0] shift_left_result;
    wire [WIDTH-1:0] shift_right_result;

    // Left Shifter Submodule
    shift_left_unit #(
        .WIDTH(WIDTH)
    ) u_shift_left (
        .data_in(din),
        .shift_left_data(shift_left_result)
    );

    // Right Shifter Submodule
    shift_right_unit #(
        .WIDTH(WIDTH)
    ) u_shift_right (
        .data_in(din),
        .shift_right_data(shift_right_result)
    );

    // Output Selector
    always @(posedge clk or posedge rst) begin
        if (rst)
            dout <= {WIDTH{1'b0}};
        else
            dout <= dir ? shift_right_result : shift_left_result;
    end

endmodule

// -----------------------------------------------------------------------------
// shift_left_unit: Performs left shift by 1 bit
// -----------------------------------------------------------------------------
module shift_left_unit #(
    parameter WIDTH=16
)(
    input  [WIDTH-1:0] data_in,
    output [WIDTH-1:0] shift_left_data
);

    assign shift_left_data = data_in << 1;

endmodule

// -----------------------------------------------------------------------------
// shift_right_unit: Performs right shift by 1 bit using conditional invert-sub8
// -----------------------------------------------------------------------------
module shift_right_unit #(
    parameter WIDTH=16
)(
    input  [WIDTH-1:0] data_in,
    output [WIDTH-1:0] shift_right_data
);

    wire [WIDTH-1:0] right_result;

    generate
        if (WIDTH == 8) begin : GEN_WIDTH8
            wire [7:0] cond_sub_result;
            cond_inv_sub8 u_cond_inv_sub8 (
                .a(data_in[7:0]),
                .b(8'b00000001),
                .result(cond_sub_result)
            );
            assign right_result = cond_sub_result >> 1;
        end else if (WIDTH == 16) begin : GEN_WIDTH16
            wire [7:0] din_upper;
            wire [7:0] din_lower;
            wire [7:0] res_upper;
            wire [7:0] res_lower;
            assign din_upper = data_in[15:8];
            assign din_lower = data_in[7:0];
            cond_inv_sub8 u_cond_inv_sub8_upper (
                .a(din_upper),
                .b(8'b00000001),
                .result(res_upper)
            );
            cond_inv_sub8 u_cond_inv_sub8_lower (
                .a(din_lower),
                .b(8'b00000001),
                .result(res_lower)
            );
            assign right_result = {res_upper >> 1, res_lower >> 1};
        end else begin : GEN_WIDTH_OTHER
            integer j;
            reg [WIDTH-1:0] shift_temp;
            always @(*) begin
                for (j = 0; j < WIDTH; j = j + 1) begin
                    if (j == WIDTH-1)
                        shift_temp[j] = 1'b0;
                    else
                        shift_temp[j] = data_in[j+1];
                end
            end
            assign right_result = shift_temp;
        end
    endgenerate

    assign shift_right_data = right_result;

endmodule

// -----------------------------------------------------------------------------
// cond_inv_sub8: 8-bit Conditional Invert Subtractor
// Computes a - b = a + (~b) + 1
// -----------------------------------------------------------------------------
module cond_inv_sub8(
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] result
);
    reg [7:0] sum;
    reg [7:0] b_inv;
    reg carry_in;
    integer i;
    always @(*) begin
        b_inv = ~b;
        carry_in = 1'b1;
        for (i = 0; i < 8; i = i + 1) begin
            sum[i] = a[i] ^ b_inv[i] ^ carry_in;
            carry_in = (a[i] & b_inv[i]) | (a[i] & carry_in) | (b_inv[i] & carry_in);
        end
    end
    assign result = sum;
endmodule