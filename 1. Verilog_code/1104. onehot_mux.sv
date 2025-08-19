module onehot_mux (
    input wire [3:0] one_hot_sel, // One-hot selection
    input wire [7:0] in0, in1, in2, in3, // Data inputs
    output wire [7:0] data_out    // Selected output
);
    assign data_out = ({8{one_hot_sel[0]}} & in0) |
                      ({8{one_hot_sel[1]}} & in1) |
                      ({8{one_hot_sel[2]}} & in2) |
                      ({8{one_hot_sel[3]}} & in3);
endmodule