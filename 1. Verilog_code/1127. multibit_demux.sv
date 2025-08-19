module multibit_demux #(
    parameter DATA_WIDTH = 4,             // Width of data bus
    parameter OUT_COUNT = 4               // Number of outputs
) (
    input wire [DATA_WIDTH-1:0] data_in,  // Input data bus
    input wire [1:0] select,              // Selection input
    output wire [DATA_WIDTH*OUT_COUNT-1:0] demux_out // Combined outputs
);
    // Generate bus-width demultiplexer using generate statements
    genvar i;
    generate
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin : bit_demux
            assign demux_out[i] = (select == 2'b00) ? data_in[i] : 1'b0;
            assign demux_out[DATA_WIDTH+i] = (select == 2'b01) ? data_in[i] : 1'b0;
            assign demux_out[2*DATA_WIDTH+i] = (select == 2'b10) ? data_in[i] : 1'b0;
            assign demux_out[3*DATA_WIDTH+i] = (select == 2'b11) ? data_in[i] : 1'b0;
        end
    endgenerate
endmodule
