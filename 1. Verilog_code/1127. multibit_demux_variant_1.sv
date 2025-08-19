//SystemVerilog
module multibit_demux #(
    parameter DATA_WIDTH = 4,              // Width of data bus
    parameter OUT_COUNT = 4,               // Number of outputs
    parameter SEL_WIDTH = 2                // Width of select signal
) (
    input wire [DATA_WIDTH-1:0] data_in,   // Input data bus
    input wire [SEL_WIDTH-1:0] select,     // Selection input
    output wire [DATA_WIDTH*OUT_COUNT-1:0] demux_out // Combined outputs
);
    // Internal wires between modules
    wire [OUT_COUNT-1:0] select_onehot;
    
    // Instance of decoder module - converts binary select to one-hot
    decoder_to_onehot #(
        .SEL_WIDTH(SEL_WIDTH),
        .OUT_COUNT(OUT_COUNT)
    ) select_decoder (
        .select(select),
        .onehot(select_onehot)
    );
    
    // Instance of data routing module - routes data based on one-hot select
    data_router #(
        .DATA_WIDTH(DATA_WIDTH),
        .OUT_COUNT(OUT_COUNT)
    ) data_route (
        .data_in(data_in),
        .select_onehot(select_onehot),
        .demux_out(demux_out)
    );
endmodule

// Decoder module - converts binary select to one-hot encoding
module decoder_to_onehot #(
    parameter SEL_WIDTH = 2,
    parameter OUT_COUNT = 4
) (
    input wire [SEL_WIDTH-1:0] select,
    output wire [OUT_COUNT-1:0] onehot
);
    // Optimized binary to one-hot conversion
    assign onehot = (1'b1 << select);
endmodule

// Data routing module - routes data based on one-hot select
module data_router #(
    parameter DATA_WIDTH = 4,
    parameter OUT_COUNT = 4
) (
    input wire [DATA_WIDTH-1:0] data_in,
    input wire [OUT_COUNT-1:0] select_onehot,
    output wire [DATA_WIDTH*OUT_COUNT-1:0] demux_out
);
    // Optimized data routing implementation
    genvar i;
    generate
        for (i = 0; i < OUT_COUNT; i = i + 1) begin : out_groups
            assign demux_out[DATA_WIDTH*(i+1)-1:DATA_WIDTH*i] = 
                select_onehot[i] ? data_in : {DATA_WIDTH{1'b0}};
        end
    endgenerate
endmodule