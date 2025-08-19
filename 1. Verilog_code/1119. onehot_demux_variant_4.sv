//SystemVerilog
//-----------------------------------------------------------------------------
// Top-level Module: onehot_demux
// Description: Hierarchical 1-to-4 one-hot demultiplexer with modular subblocks
//-----------------------------------------------------------------------------
module onehot_demux (
    input  wire        data_in,        // Input data
    input  wire [3:0]  one_hot_sel,    // One-hot selection (only one bit active)
    output wire [3:0]  data_out        // Output channels
);

    // Internal signals for each demux channel
    wire [3:0] channel_out;

    // Instantiate selection decoder
    onehot_sel_decoder #(
        .WIDTH(4)
    ) u_sel_decoder (
        .one_hot_sel (one_hot_sel),
        .sel_valid   (sel_valid)
    );

    // Instantiate data distribution module
    onehot_data_distributor #(
        .WIDTH(4)
    ) u_data_distributor (
        .data_in   (data_in),
        .sel       (one_hot_sel),
        .data_out  (channel_out)
    );

    // Output buffer module to drive the final outputs
    onehot_output_buffer #(
        .WIDTH(4)
    ) u_output_buffer (
        .data_in   (channel_out),
        .data_out  (data_out)
    );

endmodule

//-----------------------------------------------------------------------------
// Module: onehot_sel_decoder
// Description: Decodes one-hot selection, provides valid signal if only one bit is high
//-----------------------------------------------------------------------------
module onehot_sel_decoder #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] one_hot_sel, // One-hot selection vector
    output wire             sel_valid    // High if exactly one bit in one_hot_sel is high
);
    assign sel_valid = (one_hot_sel != 0) && ((one_hot_sel & (one_hot_sel - 1)) == 0);
endmodule

//-----------------------------------------------------------------------------
// Module: onehot_data_distributor
// Description: Distributes input data to output channels based on one-hot selection
//-----------------------------------------------------------------------------
module onehot_data_distributor #(
    parameter WIDTH = 4
)(
    input  wire        data_in,    // Input data
    input  wire [WIDTH-1:0] sel,   // One-hot selection vector
    output wire [WIDTH-1:0] data_out // Distributed output channels
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : GEN_DATA_DISTRIB
            // For each channel, use logic AND between data and corresponding selection bit
            assign data_out[i] = data_in & sel[i];
        end
    endgenerate
endmodule

//-----------------------------------------------------------------------------
// Module: onehot_output_buffer
// Description: Output buffer to drive final demux outputs (optional, for structure)
//-----------------------------------------------------------------------------
module onehot_output_buffer #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] data_in,   // Input channels
    output wire [WIDTH-1:0] data_out   // Buffered outputs
);
    assign data_out = data_in;
endmodule