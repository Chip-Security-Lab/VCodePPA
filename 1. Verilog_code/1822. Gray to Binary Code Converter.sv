module gray2bin_unit #(parameter DATA_WIDTH = 8) (
    input  [DATA_WIDTH-1:0] gray_data,
    output [DATA_WIDTH-1:0] binary_data
);
    // Binary conversion is cumulative XOR
    genvar gv;
    generate
        for (gv = 0; gv < DATA_WIDTH; gv = gv + 1) begin : g2b_conv
            assign binary_data[gv] = ^(gray_data >> gv);
        end
    endgenerate
endmodule