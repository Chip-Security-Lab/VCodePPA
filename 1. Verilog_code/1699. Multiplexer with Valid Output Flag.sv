module mux_with_valid #(
    parameter W = 32
)(
    input [W-1:0] in_data[0:3],
    input [1:0] select,
    input in_valid[0:3],
    output [W-1:0] out_data,
    output out_valid
);
    assign out_data = in_data[select];
    assign out_valid = in_valid[select];
endmodule