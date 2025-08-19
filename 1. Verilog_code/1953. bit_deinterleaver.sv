module bit_deinterleaver #(
    parameter INTLV_WIDTH = 16
)(
    input [INTLV_WIDTH-1:0] intlv_data,  // 必须是偶数宽度
    output [INTLV_WIDTH/2-1:0] data_odd, data_even
);
    genvar j;
    generate
        for (j = 0; j < INTLV_WIDTH/2; j = j + 1) begin: deintlv
            assign data_even[j] = intlv_data[2*j];
            assign data_odd[j] = intlv_data[2*j+1];
        end
    endgenerate
endmodule