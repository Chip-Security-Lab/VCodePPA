//SystemVerilog
module multi_channel_parity #(
    parameter CHANNELS = 4,
    parameter WIDTH = 8
)(
    input [CHANNELS*WIDTH-1:0] ch_data,
    output [CHANNELS-1:0] ch_parity
);
    // Internal signals for connecting child modules
    wire [WIDTH-1:0] channel_data [0:CHANNELS-1];
    
    // Split the input data into individual channel data
    genvar i;
    generate
        for (i = 0; i < CHANNELS; i = i+1) begin : gen_data_split
            assign channel_data[i] = ch_data[i*WIDTH +: WIDTH];
        end
    endgenerate
    
    // Instantiate single parity calculators for each channel
    generate
        for (i = 0; i < CHANNELS; i = i+1) begin : gen_parity_calc
            single_channel_parity #(
                .WIDTH(WIDTH)
            ) parity_inst (
                .data(channel_data[i]),
                .parity(ch_parity[i])
            );
        end
    endgenerate
endmodule

// Single channel parity calculator module
module single_channel_parity #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data,
    output parity
);
    // Calculate parity using reduction XOR operator
    assign parity = ^data;
endmodule