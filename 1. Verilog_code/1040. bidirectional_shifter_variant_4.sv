//SystemVerilog
module bidirectional_shifter #(parameter DATA_W=16) (
    input  [DATA_W-1:0] data,
    input  [$clog2(DATA_W)-1:0] amount,
    input  left_not_right,   // Direction control
    input  arithmetic_shift, // 1=arithmetic, 0=logical
    output [DATA_W-1:0] result
);
    wire [DATA_W-1:0] left_shift_result;
    wire [DATA_W-1:0] logical_right_shift_result;
    wire [DATA_W-1:0] arithmetic_right_shift_result;

    // Barrel shifter for left shift (logical)
    barrel_shifter_left #(.DATA_W(DATA_W)) u_barrel_shifter_left (
        .data_in(data),
        .shift_amt(amount),
        .data_out(left_shift_result)
    );

    // Barrel shifter for right shift (logical)
    barrel_shifter_right #(.DATA_W(DATA_W)) u_barrel_shifter_right (
        .data_in(data),
        .shift_amt(amount),
        .arithmetic(1'b0),
        .data_out(logical_right_shift_result)
    );

    // Barrel shifter for right shift (arithmetic)
    barrel_shifter_right #(.DATA_W(DATA_W)) u_barrel_shifter_right_arith (
        .data_in(data),
        .shift_amt(amount),
        .arithmetic(arithmetic_shift),
        .data_out(arithmetic_right_shift_result)
    );

    assign result = left_not_right ? left_shift_result :
                    (arithmetic_shift ? arithmetic_right_shift_result : logical_right_shift_result);

endmodule

module barrel_shifter_left #(parameter DATA_W=16) (
    input  [DATA_W-1:0] data_in,
    input  [$clog2(DATA_W)-1:0] shift_amt,
    output [DATA_W-1:0] data_out
);
    wire [DATA_W-1:0] stage [0:$clog2(DATA_W)];

    assign stage[0] = data_in;

    genvar i;
    generate
        for (i = 0; i < $clog2(DATA_W); i = i + 1) begin : left_shift_stages
            assign stage[i+1] = shift_amt[i] ?
                {stage[i][DATA_W-1-(1<<i):0], {1<<i{1'b0}}} :
                stage[i];
        end
    endgenerate

    assign data_out = stage[$clog2(DATA_W)];
endmodule

module barrel_shifter_right #(parameter DATA_W=16) (
    input  [DATA_W-1:0] data_in,
    input  [$clog2(DATA_W)-1:0] shift_amt,
    input  arithmetic, // 1=arithmetic, 0=logical
    output [DATA_W-1:0] data_out
);
    wire [DATA_W-1:0] stage [0:$clog2(DATA_W)];
    wire sign_bit;
    assign sign_bit = arithmetic ? data_in[DATA_W-1] : 1'b0;

    assign stage[0] = data_in;

    genvar j;
    generate
        for (j = 0; j < $clog2(DATA_W); j = j + 1) begin : right_shift_stages
            assign stage[j+1] = shift_amt[j] ?
                {{(1<<j){sign_bit}}, stage[j][DATA_W-1:1<<j]} :
                stage[j];
        end
    endgenerate

    assign data_out = stage[$clog2(DATA_W)];
endmodule