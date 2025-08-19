//SystemVerilog

//-----------------------------------------------------------------------------
// Submodule: onehot_decoder
// Function: Decodes a 4-bit one-hot selection signal and generates enable signals
//-----------------------------------------------------------------------------
module onehot_decoder (
    input  wire [3:0] one_hot_sel,  // One-hot selection input
    output wire [3:0] enable        // One-hot decoded enable outputs
);
    assign enable = one_hot_sel;
endmodule

//-----------------------------------------------------------------------------
// Submodule: data_gater
// Function: Gates input data to four output channels based on enable signals
//-----------------------------------------------------------------------------
module data_gater (
    input  wire        data_in,     // Input data
    input  wire [3:0]  enable,      // Enable signals for each output
    output wire [3:0]  data_out     // Gated data outputs
);
    assign data_out[0] = data_in & enable[0];
    assign data_out[1] = data_in & enable[1];
    assign data_out[2] = data_in & enable[2];
    assign data_out[3] = data_in & enable[3];
endmodule

//-----------------------------------------------------------------------------
// Top Module: onehot_demux
// Function: Hierarchical one-hot demultiplexer
//-----------------------------------------------------------------------------
module onehot_demux (
    input  wire        data_in,         // Input data
    input  wire [3:0]  one_hot_sel,     // One-hot selection (only one bit active)
    output wire [3:0]  data_out         // Output channels
);

    wire [3:0] enable_signals;

    // Decode the one-hot select signal
    onehot_decoder u_decoder (
        .one_hot_sel(one_hot_sel),
        .enable(enable_signals)
    );

    // Gate the data input to the correct output channel(s)
    data_gater u_gater (
        .data_in(data_in),
        .enable(enable_signals),
        .data_out(data_out)
    );

endmodule