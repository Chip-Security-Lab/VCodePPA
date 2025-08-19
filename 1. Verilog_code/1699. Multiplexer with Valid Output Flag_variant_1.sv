//SystemVerilog
module subtractor_with_borrow (
    input [1:0] a,
    input [1:0] b,
    output [1:0] result,
    output borrow_out
);

    wire borrow0, borrow1;
    wire temp_result0, temp_result1;

    // First bit subtraction with borrow
    assign temp_result0 = a[0] ^ b[0];
    assign borrow0 = ~a[0] & b[0];

    // Second bit subtraction with borrow
    assign temp_result1 = a[1] ^ b[1] ^ borrow0;
    assign borrow1 = (b[1] & ~a[1]) | (borrow0 & ~a[1]);

    assign result = {temp_result1, temp_result0};
    assign borrow_out = borrow1;

endmodule

module mux_with_valid #(
    parameter W = 2
)(
    input [W-1:0] in_data[0:3],
    input [1:0] select,
    input in_valid[0:3],
    output [W-1:0] out_data,
    output out_valid
);

    // Data path mux
    mux_data_path #(
        .W(W)
    ) data_path (
        .in_data(in_data),
        .select(select),
        .out_data(out_data)
    );

    // Valid signal mux
    mux_valid_path valid_path (
        .in_valid(in_valid),
        .select(select),
        .out_valid(out_valid)
    );

endmodule

module mux_data_path #(
    parameter W = 2
)(
    input [W-1:0] in_data[0:3],
    input [1:0] select,
    output [W-1:0] out_data
);
    assign out_data = in_data[select];
endmodule

module mux_valid_path (
    input in_valid[0:3],
    input [1:0] select,
    output out_valid
);
    assign out_valid = in_valid[select];
endmodule