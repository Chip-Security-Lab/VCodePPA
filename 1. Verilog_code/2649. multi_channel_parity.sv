module multi_channel_parity #(
    parameter CHANNELS = 4,
    parameter WIDTH = 8
)(
    input [CHANNELS*WIDTH-1:0] ch_data,
    output [CHANNELS-1:0] ch_parity
);
    genvar i;
    generate
        for (i=0; i<CHANNELS; i=i+1) begin : gen_parity
            wire [WIDTH-1:0] data = ch_data[i*WIDTH +: WIDTH];
            assign ch_parity[i] = ^data;
        end
    endgenerate
endmodule