module onehot_demux (
    input wire data_in,                   // Input data
    input wire [3:0] one_hot_sel,         // One-hot selection (only one bit active)
    output wire [3:0] data_out            // Output channels
);
    // Direct one-hot selection using bitwise AND
    assign data_out[0] = data_in & one_hot_sel[0];
    assign data_out[1] = data_in & one_hot_sel[1];
    assign data_out[2] = data_in & one_hot_sel[2];
    assign data_out[3] = data_in & one_hot_sel[3];
endmodule